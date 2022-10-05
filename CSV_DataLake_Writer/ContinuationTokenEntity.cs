using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.DurableTask;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSV_DataLake_Writer
{
    [JsonObject(MemberSerialization.OptIn)]
    public class ContinuationTokenEntity
    {
        [JsonProperty("continuationToken")]
        public string ContinuationToken { get; set; }

        public string Get() => this.ContinuationToken;
        public void Set(string token) => this.ContinuationToken = token;

        [FunctionName(nameof(ContinuationTokenEntity))]
        public static Task Run([EntityTrigger] IDurableEntityContext ctx) => ctx.DispatchAsync<ContinuationTokenEntity>();
    }
}
