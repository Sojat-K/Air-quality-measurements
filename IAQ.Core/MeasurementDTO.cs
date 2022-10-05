namespace IAQ.Core
{
    public class MeasurementDTO
    {
        public Guid id { get; set; } = Guid.NewGuid();
        public string deviceId { get; set; } = string.Empty;
        public int? co2 { get; set; }
        public int? humidity { get; set; }
        public int? temp { get; set; }
        public double? pressure { get; set; }
        public int? voc { get; set; }
        public DateTime time { get; set; }
    }
}