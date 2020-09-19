const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);

var msgData;

exports.eventTrigger = functions.firestore.document(
    'event/{eventId}'
).onCreate((snapshot, context) => {
    msgData = snapshot.data();

    var deviceList = msgData.devices;

    var payload = {
        "notification": {
            "title": "Attendance reminder",
            "body": "Attendance reminder from " + msgData.name,
            "sound": "default"
        },
        "data": {
            "sendername": msgData.name,
            "message": "Attendance reminder"
        }
    }

    return admin.messaging().sendToDevice(deviceList, payload).then((response) => {
        console.log("sent succesfully");
    }).catch((e) => {
        console.log(e);
    })

})