/**
 * @description Custom controller for CalculateDistanceMatrixGoogleMaps class
 *
 * @date May 2017
 *
 * @author  Onofrio Falco
 */
public with sharing class CalculateDistanceMatrixGoogleMapsCtrl {
	public String account1Id 		{get; set;}
	public Account account1 		{get; set;}
	public String account1Address 	{get; set;}
	public String account2Id 		{get; set;}
	public Account account2 		{get; set;}
	public String account2Address 	{get; set;}
	public CalculateDistanceMatrixGoogleMapsCtrl() {
		updateAccounts();
	}


	/*------- INIT METHODS -------*/

	public List<Account> getAccounts() {
		return accounts;
	}

	public void updateAccounts() {

		if (!accounts.isEmpty()) {
			accounts.clear();
		}

		this.accounts = [SELECT ID, 
								Name, 
								ShippingStreet, 
								ShippingCity, 
								ShippingState, 
								ShippingPostalCode, 
								ShippingCountry 
						 FROM Account
						 WHERE ShippingStreet <> ''
						 LIMIT 100];

	}

	public void updateAccountVariables() {

		for (Account a : accounts) {
			if (a.ID == account1Id) {
				account1 = a;
			}
			if (a.ID == account2Id) {
				account2 = a;
			}
		}

	}

	public Boolean updateAccountAddresses() {

		if ((
				String.isBlank(account1.ShippingStreet) 
				&& String.isBlank(account1.ShippingCity)
				&& String.isBlank(account1.ShippingState)
				&& String.isBlank(account1.ShippingPostalCode)
				&& String.isBlank(account1.ShippingCountry)
			) && (
				String.isBlank(account2.ShippingStreet)
				&& String.isBlank(account2.ShippingCity)
				&& String.isBlank(account2.ShippingState)
				&& String.isBlank(account2.ShippingPostalCode)
				&& String.isBlank(account2.ShippingCountry)
			)) {

			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Impossible build addresses for API call. Some fields are missing'));
			return false;

		}

		account1Address = EncodingUtil.urlEncode((
			account1.ShippingStreet + ' ' + 
			account1.ShippingCity + ' ' + 
			account1.ShippingState + ' ' + 
			account1.ShippingPostalCode + ' ' + 
			account1.ShippingCountry).trim(),
			'UTF-8');

		account2Address = EncodingUtil.urlEncode((
			account2.ShippingStreet + ' ' + 
			account2.ShippingCity + ' ' + 
			account2.ShippingState + ' ' +
			account2.ShippingPostalCode + ' ' +
			account2.ShippingCountry).trim(), 
			'UTF-8');

		System.debug('*** account1Address: ' + account1Address + ' , account2Address: ' + account2Address);
		return true;

	}


	/*------- SELECT OPTION -------*/

	public List<SelectOption> getAccountOptions() {

		List <SelectOption> options = new List <SelectOption>();
		options.add(new SelectOption('', '--None--'));
		for (Account a : accounts) {
			options.add(new SelectOption(a.Id, a.Name));
		}
		return options;

	}


	/*------- CONTROLLER ACTIONS -------*/

	public void btnCalculateDistance() {

		/* Some validations needed */
		if ((account1Id == null || account1Id == '') || (account2Id == null || account2Id == '')) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Select two Accounts and then resubmit'));
			return;
		}

		if (account1Id.equals(account2Id)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The two accounts must be different'));
			return;
		}
		/* End validations */

		updateAccountVariables();
		boolean response = updateAccountAddresses();
		if (response) {
			CalculateDistanceMatrixGoogleMaps gm = new CalculateDistanceMatrixGoogleMaps(account1Address, account2Address);
			this.distance 	= isNull(gm.distance) ? 0.0 : gm.distance;
			this.duration 	= isNull(gm.duration) ? 'empty' : gm.duration;
			this.travelTime = isNull(gm.travelTime) ? 0 : gm.travelTime;
		} else {
			this.distance 	= 0.0;
			this.duration 	= 'empty';
			this.travelTime = 0;
		}
	}


	/*------- UTILS -------*/

	public List <Account> accounts = new List <Account>();

	public Decimal distance 	{get; set;}
	public String duration 		{get; set;}
	public Integer travelTime 	{get; set;}

	public Boolean isNull(Object obj) {
		if (obj == null) {
			return true;
		}
		if (obj instanceof String) {
			if ((String)obj == '') {
				return true;
			}
		}
		if (obj instanceof Decimal) {
			if ((Decimal) obj == 0.0) {
				return true;
			}
		}
		if (obj instanceof Integer) {
			if ((Integer) obj == 0) {
				return true;
			}
		}
		return false;
	}

	public Boolean isDigit(Object obj) {
		Pattern p = Pattern.compile('^\\d+$');
		Matcher m = p.matcher((String)obj);
		if (m.find()) {
			return true;
		}
		return false;
	}

	public Boolean isText(Object obj) {
		Pattern p = Pattern.compile('^[a-zA-Z ]*$');
		Matcher m = p.matcher((String)obj);
		if (m.find()) {
			return true;
		}
		return false;
	}

}