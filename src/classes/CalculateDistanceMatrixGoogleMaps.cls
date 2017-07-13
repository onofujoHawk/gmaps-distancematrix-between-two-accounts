/**
 * @description Use Google Maps API in Salesforce.com
 * calculate distance matrix between two Accounts
 *
 * @date May 2017
 *
 * @author Onofrio Falco
 */
public class CalculateDistanceMatrixGoogleMaps {
	public String duration 		{get; set;}
	public Integer travelTime 	{get; set;}
	public Decimal distance 	{get; set;}
	public CalculateDistanceMatrixGoogleMaps(String origin, String destination) {
		String jsonResults = getJsonResults(origin, destination);
		parseJsonResults(jsonResults);
		//jsonResults = formatJsonResults(jsonResults);
		//updateJsonSections(jsonResults);
	}


	/*------ USE GOOGLE MAPS API ------*/

	public String getJsonResults(String origin, String destination) {

		HttpRequest req = new HttpRequest();
		Http http = new Http();

		req.setMethod('GET');

		String API_KEY 	= 'AIzaSyDePQFQ2F-9XpDhmQKqndbeG_XB9TMcX3s';
		String GMAP_URL = 'https://maps.googleapis.com/maps/api/distancematrix/json' + '?key=' + API_KEY + '&origins=' + origin + '&destinations=' + destination + '&mode=driving&sensor=false&language=en&units=imperial';

		req.setEndpoint(GMAP_URL);

		HttpResponse resp = http.send(req);
		String jsonResults = resp.getBody().replace('\n', '');

		System.debug('jsonResult: ' + JSON.deserializeUntyped(jsonResults));

		return jsonResults;
	}


	/*------ SOLUTION THAT USE JSON PARSER ------*/

	public void parseJsonResults(String jsonResults) {

		JSONParser parser = JSON.createParser(jsonResults);
		Set <CalculateDistanceMatrixGoogleMaps.Rows> rows = new Set <CalculateDistanceMatrixGoogleMaps.Rows>();

		while(parser.nextToken() != null) 
		{
			if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getCurrentName().contains('rows')) 
			{
				System.debug('Parsing Token: ' + parser.getCurrentToken() + ' -- Name: ' + parser.getCurrentName());				
				parser.nextToken();
				if (parser.getCurrentToken() == JSONToken.START_ARRAY) 
				{
					parser.nextToken();
					if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
					{
						CalculateDistanceMatrixGoogleMaps.Rows singleRow = (CalculateDistanceMatrixGoogleMaps.Rows) parser.readValueAs(CalculateDistanceMatrixGoogleMaps.Rows.class);
						rows.add(singleRow);
	                    String serializedRows = JSON.serializePretty(rows);
	                    System.debug('*** Serialized Rows: ' + serializedRows);
	                    parser.skipChildren();
					}
				}				
			}
		}

		System.debug('Rows object from JSON ' + rows);

		String textDistance;
		String textDuration;

		if (!rows.isEmpty()) 
		{
			for (Rows row : rows) 
			{
				for (Elements el : row.elements) 
				{
					if (!el.status.equals('NOT_FOUND'))
					{
						textDistance = el.distance.text;
						textDuration = el.duration.text;
					}
				}
			}
		}

		Integer tmpMinutes = 0;
		String prevDurationNode = '';
		
		//Evaluate travel time
		if (textDuration != null) 
		{
			//Evaluate duration
			this.duration = textDuration;
			String[] durationNodes = textDuration.split('\\s+');

			for (String durationNode : durationNodes) 
			{
				if (durationNode.contains('day') || durationNode.contains('days')) {
					tmpMinutes += Integer.valueOf(prevDurationNode) * 1440;
				}
				if (durationNode.contains('hour') || durationNode.contains('hours')) {
					tmpMinutes += Integer.valueOf(prevDurationNode) * 60;
				}
				if (durationNode.contains('min') || durationNode.contains('mins')) {
					tmpMinutes += Integer.valueOf(prevDurationNode);
				}

				prevDurationNode = durationNode;
			}

			this.travelTime = tmpMinutes;
		}

		//Evaluate distance
		if (textDistance != null) {
			this.distance = Decimal.valueOf(textDistance.split('\\s+')[0].trim());
		}
		
 		System.debug('Distance: ' + distance);
 		System.debug('Travel Time: ' + travelTime);
 		System.debug('Duration: ' + duration);

	}

	public class Rows {
		public List <Elements> elements;
		public Rows(List <Elements> elements) {
			this.elements = elements.clone();
		}
	}

	public class Elements {
		public Distance distance;
		public Duration duration;
		public String status;
		public Elements(Distance distance, Duration duration, String status) {
			this.distance = distance;
			this.duration = duration;
			this.status = status;
		}
	}

	public class Duration {
		public String text;
		public Integer value;
		public Duration(String text, Integer value) {
			this.text = text;
			this.value = value;
		}
	}

	public class Distance {
		public String text;
		public Integer value;
		public Distance(String text, Integer value) {
			this.text = text;
			this.value = value;
		}
	} 


	/*------ SOLUTION WITHOUT USE JSON PARSER ------*/

	public String formatJsonResults(String value) {
        
        value = value.replace('{', ', ');
        value = value.replace('}', ', ');
        value = value.replace('[', ', ');
        value = value.replace(']', ', ');
        value = value.replace('"', '');
        
        return value;   
    }

	public void updateJsonSections(String jsonResults) {
        
        List <String> jsonSections = jsonResults.split(', ');
        
        for (Integer i = 0; i < jsonSections.size(); i++) {
            jsonSections[i] = jsonSections[i].trim();
            
            if (jsonSections[i].contains('duration :')) {
                duration = parseDuration(jsonSections[i + 1]);
                travelTime = parseTravelTime(duration);
            }
            
            if (jsonSections[i].contains('distance :')) {
                distance = parseDistance(jsonSections[i + 1]);
            }
        }
    }

    public Decimal parseDistance(String value) {
        value = value.replace('text : ', '');
        value = value.replace(' mi', '');
        value = value.replace(' ft', '');
        value = value.replace(',', '');
        value = value.trim();
        
        return Decimal.valueOf(value);
    }
    
    public String parseDuration(String value) {
        value = value.replace('text : ', '');
        
        return value;
    }
    
    public Integer parseTravelTime(String value) {
    
        Integer tmpMinutes = 0;
    
        List <String> durationNodes = value.split(' ');
        String prevDurationNode = '';
        
        for (String durationNode : durationNodes) {
            if (durationNode == 'day' || durationNode == 'days') {
                tmpMinutes += Integer.valueOf(prevDurationNode) * 1440;
            }
            if (durationNode == 'hour' || durationNode == 'hours') {
                tmpMinutes += Integer.valueOf(prevDurationNode) * 60;
            }
            if (durationNode == 'min' || durationNode == 'mins') {
                tmpMinutes += Integer.valueOf(prevDurationNode);
            }
            
            prevDurationNode = durationNode;
        }
    
        return tmpMinutes;  
    }

    //for test purpose 
    String gmapStub = '{"originAddresses":["Greenwich, Greater London, UK","13 Great Carleton Square, Edinburgh, City of Edinburgh EH16 4, UK"],"destinationAddresses":["Stockholm County, Sweden","Dlouhá 609/2, 110 00 Praha-Staré Město, Česká republika"],"rows":[{"elements":[{"status":"OK","duration":{"value":70778,"text":"19 hours 40 mins"},"distance":{"value":1887508,"text":"1173 mi"}},{"status":"OK","duration":{"value":44476,"text":"12 hours 21 mins"},"distance":{"value":1262780,"text":"785 mi"}}]},{"elements":[{"status":"OK","duration":{"value":96000,"text":"1 day 3 hours"},"distance":{"value":2566737,"text":"1595 mi"}},{"status":"OK","duration":{"value":69698,"text":"19 hours 22 mins"},"distance":{"value":1942009,"text":"1207 mi"}}]}]}';

}