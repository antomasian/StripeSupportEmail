const express = require("express");
const app = express();
const { resolve } = require("path");

app.use(express.static("."));
app.use(express.json());

app.get("/get_pub_key", async (req,res) => {
  var publishable_key = process.env.publishable_key
  
  res.send({
    publishableKey: publishable_key
  });
});

app.post("/get_pub_key", async (req, res) => {
  var publishable_key = process.env.publishable_key
  
  res.send({
    publishableKey: publishable_key
  });
});

app.post("/create_pi", async (req, res) => { 
  var piParams = {
    amount: 100,
    currency: "usd",
    payment_method_types: ["card"]
  };
  var publishable_key = process.env.publishable_key
  var secret_key = process.env.secret_key 

  var stripe = require("stripe")(secret_key);
  
  const paymentIntent = await stripe.paymentIntents.create(piParams);

  // Send the object keys to the client
  res.send({
    publishableKey: publishable_key, // https://stripe.com/docs/keys#obtain-api-keys
    paymentIntent: paymentIntent.client_secret
  });
});

const port = parseInt(process.env.PORT) || 8080;
app.listen(port, () => console.log('Node server listening on port 8080!'));