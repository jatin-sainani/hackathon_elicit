let data;
db.doc('users/OKHkh2OgKk3veC31QDG4').get().then(snapshot => {
    data = snapshot.data();
    console.log(data)
});
