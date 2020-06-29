const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

exports.onCreateFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
     .onCreate(async (snapshot, context) => {
     console.log("Follower Created", snapshot.data());
        const userId = context.params.userId;
        const followerId = context.params.followerId;

        // Create followed users Posts ref
        const followedUserPostsRef = admin
                 .firestore()
                 .collection('posts')
                 .doc(userId)
                 .collection('userPosts');

        // Create following user's Timeline ref
        const timelinePostsRef = admin
                .firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')

        // Get the followed users post
        const querySnapshot = await followedUserPostsRef.get();

        // 4 Add each users post to following user's timeline
        querySnapshot.forEach(doc => {
            if(doc.exists){
                const postId = doc.id;
                doc.data();
                timelinePostsRef.doc(postId).set(postData);
            }
        })
     })
