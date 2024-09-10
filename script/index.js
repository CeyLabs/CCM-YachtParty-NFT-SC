require("dotenv").config();
const express = require("express");
const fs = require("fs");
const app = express();
const PORT = 3000;

app.use(express.json());

app.post("/create-metadata", (req, res) => {
  const { id, ticketType, ccmCount } = req.body;

  if (!id || !ticketType || !ccmCount) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  const metadata = generateNFTMetadata(id, ticketType, ccmCount);

  fs.writeFile(`./metadata/${id}.json`, JSON.stringify(metadata), (err) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Error writing file" });
    }
    res
      .status(201)
      .json({ message: "Metadata created successfully", metadata });
  });
});

app.get("/metadata/:id", (req, res) => {
  const { id } = req.params;

  fs.readFile(`./metadata/${id}.json`, "utf8", (err, data) => {
    if (err) {
      console.error(err);
      return res.status(404).json({ message: "Metadata not found" });
    }
    res.status(200).json(JSON.parse(data));
  });
});

function generateNFTMetadata(id, ticketType, ccmCount) {
  const nft = {
    description: `Ceylon Crypto Meetup - Yacht Party 2024: where Sri Lanka's crypto community meets, innovates, and celebrates amidst the anticipation of the 2024 halving event`,
    external_url: `https://ceylabs.io/`,
    // image: `https://ceylabs.io/yatchtickets/${id}.jpeg`,
    image: `https://api.pudgypenguins.io/lil/image/${id}`,
    name: `Ticket #${id}`,
    attributes: [],
  };

  nft.attributes.push({ trait_type: "Event ID", value: "2" });
  nft.attributes.push({ trait_type: "Event Type", value: "IRL" });
  nft.attributes.push({
    trait_type: "Location",
    value: "Somewhere in the sea on a yacht",
  });
  nft.attributes.push({ trait_type: "Participation", value: "In-Person" });
  nft.attributes.push({ trait_type: "Ticket ID", value: `${id}` });
  nft.attributes.push({ trait_type: "Ticket Type", value: `${ticketType}` });
  nft.attributes.push({ trait_type: "CCM Count", value: `${ccmCount}` });
  nft.attributes.push({ trait_type: "Block Height", value: "840,000" }); // change this to the actual value later???

  return nft;
}

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
