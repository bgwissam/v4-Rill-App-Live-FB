const functions = require("firebase-functions");

const { RtcTokenBuilder, RtcRole, RtmTokenBuilder, RtmRole } = require("agora-access-token");
const admin = require("firebase-admin");
admin.initializeApp();

const APP_ID = "d480c821a2a946d6a4d29292462a3d6f";
const APP_CERTIFICATE = "832101fbfa424e358854a936e4c13db8";

exports.tokenGenerator = functions.https.onRequest((req, res) => {
    try {
        // functions.logger.info("Token Logger", { structuredData: true });
        let channelName = req.body.channelName;
        if (!channelName) {
            return res.status(500).json({ 'error': 'channel is required' });
        }
        let uid = req.body.uid;
        //this will allow a low level security feature by assigning all users to join on the same uid
        //this feature is applicable for live streaming
        if (!uid || uid == '') {
            uid = 0;
        }
        //get the role
        let role = RtcRole.SUBSCRIBER;
        if (req.body.role == RtcRole.PUBLISHER) {
            role = RtcRole.PUBLISHER;
        }
        //get expiry time
        let expireTime = req.body.expireTime;
        if (!expireTime || expireTime == '') {
            expireTime = 3600;
        } else {
            expireTime = parseInt(expireTime, 10);
        }
        //calculate expire time privilage
        let currentTime = Math.floor(Date.now() / 1000);
        const priviledgeExpireTime = currentTime + expireTime;
        console.log(`The token generator log: ${channelName} - ${uid}`);
        const token = RtcTokenBuilder.buildTokenWithUid(APP_ID, APP_CERTIFICATE, channelName, uid, role, priviledgeExpireTime);
        return res.json({ "token": token, "uid": uid });

    } catch (e) {
        functions.logger.info(`error in initiating: ${e}`);
        functions.logger.error(`error: ${e}`);
    }
});

exports.rtmTokenGenerator = functions.https.onRequest((req, res) => {
    try {
        functions.logger.info("Token Logger", { structuredData: true });
        var channelName = req.body.channelName;
        if (!channelName) {
            return res.status(500).json({ 'error': 'channel is required' });
        }
        var uid = req.body.uid;
        //this will allow a low level security feature by assigning all users to join on the same uid
        //this feature is applicable for live streaming
        if (!uid || uid == '') {
            uid = 0;
        }
        //get the role
        var role = RtmRole.Rtm_User//"subscriber";
        // if (req.body.role == "publisher") {
        //     role = "publisher";
        // }
        //get expiry time
        var expireTime = req.body.expireTime;
        if (!expireTime || expireTime == '') {
            expireTime = 3600;
        } else {
            expireTime = parseInt(expireTime, 10);
        }
        //calculate expire time privilage
        let currentTime = Math.floor(Date.now() / 1000);
        const priviledgeExpireTime = currentTime + expireTime;

        const token = RtmTokenBuilder.buildToken(APP_ID, APP_CERTIFICATE, channelName, uid, role, priviledgeExpireTime);
        return res.json({ "token": token });
    } catch (e) {
        functions.logger.info(`error in initiating: ${e}`);
        functions.logger.error(`error: ${e}`);
    }
});