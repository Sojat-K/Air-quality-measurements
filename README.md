# Sisältää kaiken tarvittavan Azuren käyttöönottoa varten

1. Aja 'Azure bicep depl'-kansiosta ARM-templaatilla kaikki pilvipalvelut Azureen

2. Avaa Visual Studiolla IAQ_Azure_Functions.sln, ja julkaise (engl. "Publish") kumpikin projekti Azureen

3. Luo IoT Hubiin laite, ja vie laitteen connectionstring iaq.service-tiedostoon Raspberry Pi:llä (polussa '/lib/systemd/system')