using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using Azure.Storage.Blobs;
using IAQ.Core;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.DurableTask;
using Microsoft.Extensions.Logging;

namespace CSV_DataLake_Writer
{
    public class CSV_Writer
    {
        [FunctionName("CSV_Writer")]
        public async Task Run([TimerTrigger("%WritingTimer%")] TimerInfo myTimer,
            [CosmosDB(
            databaseName: "%dbName%",
            containerName: "%containerName%",
            Connection = "CosmosDB_Connection")] CosmosClient client,
            [Blob("%blobContainerName%")] BlobContainerClient blobContainerClient,
            [DurableClient] IDurableEntityClient entityClient,
            ILogger log)
        {
            Container measurementsContainer = client.GetDatabase(GetEnvironmentVariable("dbName")).GetContainer(GetEnvironmentVariable("containerName"));
            List<MeasurementDTO> measurementList = new List<MeasurementDTO>();
            FeedIterator<MeasurementDTO> feedIterator = null;

            // ContinuationToken is stored in a DurableEntity, that persists between function executions
            var contTokenId = new EntityId(nameof(ContinuationTokenEntity), "continuationToken");
            EntityStateResponse<ContinuationTokenEntity> continuationTokenResponse = await entityClient.ReadEntityStateAsync<ContinuationTokenEntity>(contTokenId);

            if (continuationTokenResponse.EntityExists)
            {
                string continuationToken = continuationTokenResponse.EntityState.Get();
                feedIterator = measurementsContainer.GetChangeFeedIterator<MeasurementDTO>(ChangeFeedStartFrom.ContinuationToken(continuationToken), ChangeFeedMode.Incremental);
            }
            else
            {
                feedIterator = measurementsContainer.GetChangeFeedIterator<MeasurementDTO>(ChangeFeedStartFrom.Time(DateTime.UtcNow.AddDays(-1)), ChangeFeedMode.Incremental);
            }
            while (feedIterator.HasMoreResults)
            {
                FeedResponse<MeasurementDTO> feedResponse = await feedIterator.ReadNextAsync();
                if (feedResponse.StatusCode == HttpStatusCode.NotModified)
                {
                    string contToken = feedResponse.ContinuationToken;
                    // Save the continuation token when done
                    await entityClient.SignalEntityAsync(contTokenId, "set", contToken);
                    break;
                }
                else
                {
                    foreach (MeasurementDTO measurementDTO in feedResponse)
                    {
                        measurementList.Add(measurementDTO);
                    }
                }
            }

            // Exit early if there were no changes made
            // (Don't write empty .csv -files to blob storage)
            if (measurementList.Count == 0) return;

            // Get a string that represents a .csv-files content
            string csvString = CSVStringFromMeasurements(measurementList);

            // UploadBlobAsync() takes in a stream, so convert string to byte array and create a memorystream to use
            byte[] asd = Encoding.ASCII.GetBytes(csvString);
            MemoryStream memoryStream = new MemoryStream(asd);

            // Save the file and close the stream
            await blobContainerClient.UploadBlobAsync($"{DateTime.UtcNow.ToString("yyyy/MM/dd/HH\\:mm\\:ss")}.csv", memoryStream);
            memoryStream.Close();

        }

        /// <summary>
        /// Simple helper to convert measurements into .csv -format string
        /// </summary>
        /// <param name="measurements">Enumerable containing MeasurementDTO's</param> 
        /// <returns>String which contains all the measurements in a comma separeted .csv -format</returns>
        private static string CSVStringFromMeasurements(IEnumerable<MeasurementDTO> measurements)
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("id,deviceId,time,temperature,humidity,co2,pressure(hPa),voc");
            foreach (MeasurementDTO measurementDTO in measurements)
            {
                sb.AppendLine($"{measurementDTO.id},{measurementDTO.deviceId},{measurementDTO.time},{measurementDTO.temp},{measurementDTO.humidity},{measurementDTO.co2}, {measurementDTO.pressure}, {measurementDTO.voc}");
            }
            return sb.ToString();
        }

        private static string GetEnvironmentVariable(string name)
        {
            return System.Environment.GetEnvironmentVariable(name, EnvironmentVariableTarget.Process);
        }
    }

}
