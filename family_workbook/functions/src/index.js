const functions = require("firebase-functions");
const admin = require("firebase-admin");
const db = admin.firestore();

exports.seedFamilyTypes = functions.https.onRequest(async (req, res) => {
  // Array of family types extracted from the manuscript
  const familyTypes = [
    { id: "biological", name: "Biological / Nuclear", description: "Biologically related parents, children, and/or grandparents." },
    { id: "shared", name: "Shared Household", description: "People sharing living space and mutual support." },
    { id: "child_headed", name: "Child-Headed", description: "Siblings taking up parental roles of leadership." },
    { id: "adoptive", name: "Adoptive", description: "Families formed through adoption or guardianship." },
    { id: "foster", name: "Foster", description: "Parents providing care for children in transition." },
    { id: "care_based", name: "Care-Based / Orphanage", description: "Carers and children bonded in a home setting." },
    { id: "displaced", name: "Displaced Community", description: "Families bonded naturally through mutual adversity." },
    { id: "blended", name: "Blended", description: "Two families combined into one (e.g., remarriage)." },
    { id: "separated", name: "Separated", description: "Parents and children living apart for economic or structural reasons." }
  ];

  try {
    const batch = db.batch();
    
    familyTypes.forEach((type) => {
      // Create a reference in SystemMetadata/config/FamilyTypes
      const docRef = db.collection("SystemMetadata").doc("config").collection("FamilyTypes").doc(type.id);
      batch.set(docRef, {
        name: type.name,
        description: type.description,
        active: true, // Allows you to turn off a type later without deleting it
        order: familyTypes.indexOf(type) // For sorting in the UI
      });
    });

    await batch.commit();
    res.status(200).send("Successfully seeded Family Types!");
  } catch (error) {
    console.error("Error seeding data:", error);
    res.status(500).send("Failed to seed data.");
  }
});