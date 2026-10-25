import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const projectId = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT;
if (!projectId) {
  throw new Error(
    'Set GOOGLE_CLOUD_PROJECT. Example: GOOGLE_CLOUD_PROJECT=lapkoyeth npm run migrate',
  );
}

initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();

function searchTokens(firstName, lastName) {
  const parts = [firstName, lastName]
    .map((value) => String(value ?? '').trim().toLocaleLowerCase('ru'))
    .filter(Boolean);
  const values = new Set(parts);
  if (parts.length) {
    values.add(parts.join(' '));
    values.add([...parts].reverse().join(' '));
  }
  const tokens = new Set();
  for (const value of values) {
    for (let index = 1; index <= value.length; index += 1) {
      tokens.add(value.slice(0, index));
    }
  }
  return [...tokens].sort();
}

let migrated = 0;
let lastDocument;

while (true) {
  let query = db.collection('users').orderBy('__name__').limit(400);
  if (lastDocument) query = query.startAfter(lastDocument);
  const snapshot = await query.get();
  if (snapshot.empty) break;

  const batch = db.batch();
  for (const document of snapshot.docs) {
    const data = document.data();
    const firstName = String(data.firstName ?? '').trim();
    const lastName = String(data.lastName ?? '').trim();
    const displayName = `${firstName} ${lastName}`.trim();
    batch.set(
      document.ref,
      {
        firstName,
        lastName,
        displayName,
        publicId: `LP-${document.id.slice(0, 8).toUpperCase()}`,
        searchTokens: searchTokens(firstName, lastName),
        profilePublic: data.profilePublic ?? true,
        petsPublic: data.petsPublic ?? true,
        email: FieldValue.delete(),
        phone: FieldValue.delete(),
        city: FieldValue.delete(),
        gender: FieldValue.delete(),
        dateOfBirth: FieldValue.delete(),
        migratedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    migrated += 1;
  }
  await batch.commit();
  lastDocument = snapshot.docs.at(-1);
  process.stdout.write(`Migrated ${migrated} users\n`);
}

process.stdout.write(`Done. Migrated ${migrated} users in ${projectId}.\n`);
