logger = require 'winston'
syslogParser = require('glossy').Parse
parseString = require('xml2js').parseString
firstCharLowerCase = require('xml2js').processors.firstCharLowerCase
Audit = require('./model/audits').Audit

parseAuditRecordFromXML = (xml, callback) ->
  options =
    mergeAttrs: true,
    explicitArray: false
    tagNameProcessors: [firstCharLowerCase]
    attrNameProcessors: [firstCharLowerCase]

  parseString xml, options, (err, result) ->
    return callback err if err

    if not result?.auditMessage
      return callback 'Document is not a valid AuditMessage'

    audit = {}

    if result.auditMessage.eventIdentification
      audit.eventIdentification = result.auditMessage.eventIdentification

    audit.activeParticipant = []
    if result.auditMessage.activeParticipant
      # xml2js will only use an array if multiple items exist (explicitArray: false), else it's an object
      if result.auditMessage.activeParticipant instanceof Array
        for ap in result.auditMessage.activeParticipant
          audit.activeParticipant.push ap
      else
        audit.activeParticipant.push result.auditMessage.activeParticipant

    if result.auditMessage.auditSourceIdentification
      audit.auditSourceIdentification = result.auditMessage.auditSourceIdentification

    audit.participantObjectIdentification = []
    if result.auditMessage.participantObjectIdentification
      # xml2js will only use an array if multiple items exist (explicitArray: false), else it's an object
      if result.auditMessage.participantObjectIdentification instanceof Array
        for poi in result.auditMessage.participantObjectIdentification
          audit.participantObjectIdentification.push poi
      else
        audit.participantObjectIdentification.push result.auditMessage.participantObjectIdentification

    callback null, audit


exports.processAudit = (msg, callback) ->
  parsedMsg = syslogParser.parse(msg)

  parseAuditRecordFromXML parsedMsg.message, (err, result) ->
    audit = new Audit result

    audit.rawMessage = msg
    audit.syslog = parsedMsg
    delete audit.syslog.originalMessage
    delete audit.syslog.message

    audit.save (saveErr) ->
      if err or saveErr
        logger.error "An error occurred while processing the audit entry: #{err}"

      callback()
