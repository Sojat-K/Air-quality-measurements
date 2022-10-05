using System;
using IAQ.Core;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace MeasurementInsert
{
    public class MeasurementInsert
    {
        [FunctionName("MeasurementInsert")]
        public void Run([ServiceBusTrigger("%queueName%", Connection = "QueueConnectionString")]string measurementMessage,
            [CosmosDB(databaseName: "%dbName%", containerName: "%containerName%", Connection = "CosmosDBConnection")] out dynamic document,
            ILogger log)
        {
            MeasurementDTO measurement = JsonConvert.DeserializeObject<MeasurementDTO>(measurementMessage);
            document = new
            {
                id = measurement.id,
                deviceId = measurement.deviceId,
                time = measurement.time.ToUniversalTime(),
                co2 = measurement.co2,
                pressure = measurement.pressure,
                temp = measurement.temp,
                humidity = measurement.humidity,
                voc = measurement.voc,
            };
        }
    }
}
