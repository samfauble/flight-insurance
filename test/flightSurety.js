
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
const { assert } = require('chai');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    //await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });


  it('registration of 5th airline needs 50% <= consensus', async () => {
    let airline2 = accounts[2];
    let airline3 = accounts[3];
    let airline4 = accounts[4];
    let airline5 = accounts[5];
    let airline6 = accounts[6];

    await config.flightSuretyApp.registerAirline(config.owner, {from: config.owner});
    await config.flightSuretyApp.registerAirline(airline2, {from: config.owner});
    await config.flightSuretyApp.registerAirline(airline3, {from: config.owner});
    await config.flightSuretyApp.registerAirline(airline4, {from: config.owner});
    await config.flightSuretyApp.registerAirline(airline5, {from: config.owner});

    await config.flightSuretyApp.registerAirline(airline6, {from: config.owner});
    await config.flightSuretyApp.registerAirline(airline6, {from: airline2});
    await config.flightSuretyApp.registerAirline(airline6, {from: airline3});
    
    assert.equal(await config.flightSuretyApp.airlines[airline6].isRegistered, true, "airline should be registered" )

    });

    it('cannot participate without funding', async () => {
        let airline2 = accounts[2];
        let airline3 = accounts[3];
    
        await config.flightSuretyApp.registerAirline(config.owner, {from: config.owner});
        await config.flightSuretyApp.registerAirline(airline2, {from: config.owner});
        
        
        assert.fail(config.flightSuretyApp.registerAirline(airline3, {from: airline2}), "airline should fail" )
    
        });
 

});
