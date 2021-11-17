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
            expireTime = 7200;
        } else {
            expireTime = parseInt(expireTime, 10);
        }
        //calculate expire time privilage
        let currentTime = Math.floor(Date.now() / 1000);
        const priviledgeExpireTime = currentTime + expireTime;
        console.log(`Role: ${role} - Expiry: ${expireTime} - Priviledge: ${priviledgeExpireTime}`);
        console.log(`RTC token: ${channelName} - uid: ${uid}`);
        const token = RtcTokenBuilder.buildTokenWithUid(APP_ID, APP_CERTIFICATE, channelName, uid, role, priviledgeExpireTime);
        return res.json({ "token": token, "uid": uid });

    } catch (e) {
        functions.logger.info(`error in initiating: ${e}`);
        functions.logger.error(`error: ${e}`);
    }
});

exports.rtmTokenGenerator = functions.https.onRequest((req, res) => {
    try {
        const channelName = req.body.channelName;
        if (!channelName) {
            return res.status(500).json({ 'error': 'channel is required' });
        }
        let userAccount = req.body.userAccount;
        //get the role
        let role = RtmRole.Rtm_User;
        //get expiry time
        let expireTime = 172800;
        //calculate expire time privilage
        let currentTime = Math.floor(Date.now() / 1000);
        const priviledgeExpireTime = currentTime + expireTime;
        console.log(`App Id: ${APP_ID}`);
        console.log(`Account: ${userAccount}`);
        console.log(`Current time: ${currentTime}`);
        console.log(`Expiry Time: ${expireTime}`);
        console.log(`current time + expire time ${priviledgeExpireTime}`);
        const token = RtmTokenBuilder.buildToken(APP_ID, APP_CERTIFICATE, userAccount, role, priviledgeExpireTime);
        console.log(`Token RTM: ${token}`);
        return res.json({ "token": token });
    } catch (e) {
        functions.logger.info(`error in initiating: ${e}`);
        functions.logger.error(`error: ${e}`);
    }
});