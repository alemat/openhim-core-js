http = require 'http'
config = require '../config/config'
application = config.get 'application'
os = require "os"
domain = os.hostname() + '.' + application.name
domain = "statsd-VirtualBox.Development"
statsd_server = config.get 'statsd'
Q = require "q"
request = require 'koa-request'
_ = require "lodash"
moment = require "moment"

# Overall Metrics

exports.retrieveTransactionCountPerHour = `function *() {
  var path = "/render?target=transformNull(summarize(stats.counters." + domain + ".Channels.count,'1hour'))&from=-1days&format=json";
  var data = [];
  var raw = yield fetchData(path);

  _.forEach(raw.data, function (item) {
    data.push({
      load: item[0],
      timestamp: moment.unix(item[1])
    });
  });
  this.body = data
}`

exports.retrieveAverageLoadTimePerHour = `function *() {
  var path = "/render?target=transformNull(summarize(stats.timers." + domain + ".Channels.mean,'1hour'))&from=-1days&format=json";
  var data = [];
  var raw = yield fetchData(path);

  _.forEach(raw.data, function (item) {
    data.push({
      avgResp: item[0],
      timestamp: moment.unix(item[1])
    });
  });
  this.body = data
}`

exports.retrieveChannelMetrics = `function *(type, channelId) {
  var data = [];
  var status_array = ['Failed','Successful', 'Completed']
  var render_url = "/render?target=transformNull(summarize(stats.counters." + domain + ".Channels." + channelId

  if (type == 'status'){
    var path = render_url + ".*.count,'1day'))&from=-7days&format=json";
    var raw = yield fetchData(path);
    console.log(JSON.stringify(raw.data));
    console.log(path);
    _.forEach(raw.data, function *(item) {
      data.push({
        failed: raw.data[i][0],
        successful: raw.data1[i][0],
      });

    });

  } else {

    var path = render_url + ".count,'1day'))&from=-7days&format=json";
        path += "&target=transformNull(summarize(stats.timers." + domain + ".Channels." + channelId + ".sum,'1day','avg'))";
    var raw = yield fetchData(path);
    var i = 0;
    _.forEach(raw.data, function (item) {
      data.push({
        load: item[0],
        avgResp: raw.data1[i][0],
        timestamp: moment.unix(item[1])
      });
      i++;
    });
  }
  this.body = data
}`

exports.retrieveSumOfTransactionsPerPeriod = `function *(period) {
  var path = '/render?target=integral(stats.counters.' + domain + '.Channels.count)&from=' + period + '&format=json';
  this.body = yield fetchData(path);
}`

exports.transactionsPerChannelPerHour = `function *(period) {
  var path = "/render?target=summarize(stats.counters." + domain + ".Channels.count,'1hour')&from=-1days&format=json";
  path = "/render?target=summarize(stats.counters.OpenHIM-core-js-preprod.Production.Channels.count,'1hour')&from=-1days&format=json";
  var data = [];
  var raw = yield fetchData(path);
  var i = 0;
  _.forEach(raw.data, function (item) {
    data.push({
      load: item[0],
      avgResp: raw.data1[i][0],
      timestamp: moment.unix(item[1])
    });
    i++;
  });
  this.body = data
}`

exports.fetchData = fetchData = `function *(path) {
  var options = {
    url: 'http://' + statsd_server.host + path
  };
  var response = yield request(options);
  var info = JSON.parse(response.body);
  var data = {};
  var i = 0;

  _.forEach(info, function (item) {
    if (i == 0) {
      data.data = item.datapoints
    } else {
      data['data' + i] = item.datapoints
    }
    i++;
  });

  return data;
}`
