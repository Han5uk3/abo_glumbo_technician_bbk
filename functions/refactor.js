const fs = require('fs');

const content = fs.readFileSync('index.js', 'utf8');
let indexJs = content;

const helpers = ['extractCustomerCoordinates', 'extractTechnicianCoordinates', 'calculateDistanceKm', 'sendAndStoreNotification', 'getAllAdminUsers', 'extractCustomerAddress'];
let utilsContent = `const admin = require('firebase-admin');
const db = admin.firestore();

`;

for (const h of helpers) {
  const marker = 'function ' + h;
  const startIdx = content.indexOf(marker);
  if (startIdx === -1) {
    const asyncMarker = 'async function ' + h;
    const asyncStartIdx = content.indexOf(asyncMarker);
    if (asyncStartIdx === -1) continue;
    let braceCount = 0;
    let foundFirstBrace = false;
    let hEndIdx = -1;
    for (let i = asyncStartIdx; i < content.length; i++) {
        if (content[i] === '{') { braceCount++; foundFirstBrace = true; }
        if (content[i] === '}') { braceCount--; }
        if (foundFirstBrace && braceCount === 0) {
            hEndIdx = i + 1;
            break;
        }
    }
    const funcContent = content.substring(asyncStartIdx, hEndIdx);
    utilsContent += funcContent + '\n\n';
    utilsContent += `module.exports.${h} = ${h};\n\n`;
    
    // Replace in index.js to use the imported version? No, we will just keep them in index.js for now to avoid breaking other functions that use them, OR we can replace them.
    // Actually, other functions in index.js might use them. The safest way is to leave the helpers in index.js, and just copy them to bookingUtils.js! Yes! Duplicate them for now to avoid a massive rewrite of all other 50 functions in index.js.
  } else {
    let braceCount = 0;
    let foundFirstBrace = false;
    let hEndIdx = -1;
    for (let i = startIdx; i < content.length; i++) {
        if (content[i] === '{') { braceCount++; foundFirstBrace = true; }
        if (content[i] === '}') { braceCount--; }
        if (foundFirstBrace && braceCount === 0) {
            hEndIdx = i + 1;
            break;
        }
    }
    const funcContent = content.substring(startIdx, hEndIdx);
    utilsContent += funcContent + '\n\n';
    utilsContent += `module.exports.${h} = ${h};\n\n`;
  }
}

fs.writeFileSync('src/utils/bookingUtils.js', utilsContent);

// Now for the booking triggers
const funcsToExtract = [
  'onBookingRequestCreated',
  'onManualJobOfferUpdated',
  'processAutoAssignments',
  'onAutoAssignmentRequestCreated',
  'syncAgentToAutoAssignment',
  'onBookingCreatedCleanupOffers',
  'onBookingRequestDeletedCleanupOffers',
  'onJobOfferCreatedForRebook'
];

let triggersContent = `const { onDocumentCreated, onDocumentWritten, onDocumentUpdated, onDocumentDeleted } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const { extractCustomerCoordinates, extractTechnicianCoordinates, calculateDistanceKm, sendAndStoreNotification, extractCustomerAddress, getAllAdminUsers } = require('../utils/bookingUtils');

`;

for (const f of funcsToExtract) {
  const marker = 'exports.' + f + ' = ';
  const startIdx = indexJs.indexOf(marker);
  if (startIdx === -1) continue;
  
  const nextExportsRegex = /\nexports\.[a-zA-Z0-9_]+ =/g;
  nextExportsRegex.lastIndex = startIdx + marker.length;
  
  let endIdx = -1;
  while(true) {
      const match = nextExportsRegex.exec(indexJs);
      if(!match) break;
      const before = indexJs.substring(startIdx, match.index);
      if(before.lastIndexOf('//') > before.lastIndexOf('\n')) continue;
      endIdx = match.index;
      break;
  }
  
  if (endIdx === -1) {
    endIdx = indexJs.length;
  }
  
  const funcStr = indexJs.substring(startIdx, endIdx);
  triggersContent += funcStr + '\n\n';
  
  // Remove from indexJs
  indexJs = indexJs.substring(0, startIdx) + indexJs.substring(endIdx);
}

fs.writeFileSync('src/triggers/bookingTriggers.js', triggersContent);

// Append exports to indexJs
indexJs += `\n// Booking Triggers\nconst bookingTriggers = require('./src/triggers/bookingTriggers');\n`;
for (const f of funcsToExtract) {
  indexJs += `exports.${f} = bookingTriggers.${f};\n`;
}

fs.writeFileSync('index.js', indexJs);
console.log('Refactoring complete!');
