# Backend Data Reference - Quick Guide

## 🔥 Firebase Collections & Data Models

### **Collection: `users`**
**Document ID:** Firebase UID
```json
{
  "uid": "string",
  "email": "string",
  "fullName": "string",
  "role": "student | admin",
  "phoneNumber": "string",
  "enrollmentId": "string | null",
  "roomId": "string | null",
  "year": "number | null",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Indexes Required:**
- role (ASC/DESC)
- email (ASC)
- enrollmentId (ASC)

---

### **Collection: `rooms`**
**Document ID:** Auto-generated or custom roomId
```json
{
  "roomId": "string",
  "blockName": "A | B | C | D",
  "roomNumber": "string",
  "floorNumber": "number",
  "capacity": "number",
  "currentOccupancy": "number",
  "occupantIds": ["uid1", "uid2"],
  "roomType": "single | double | triple | quad",
  "condition": "good | fair | needs_repair",
  "amenities": ["wifi", "ac", "attached_bathroom"],
  "monthlyRent": "number",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Computed Fields:**
- `isAvailable`: `currentOccupancy < capacity`
- `roomName`: `blockName + "-" + roomNumber`

**Indexes Required:**
- blockName (ASC), currentOccupancy (ASC)
- condition (ASC)
- roomType (ASC)

---

### **Collection: `complaints`**
**Document ID:** Auto-generated complaintId
```json
{
  "complaintId": "string",
  "studentId": "string",
  "studentName": "string",
  "category": "string",
  "determinedCategory": "plumbing | electrical | maintenance | cleanliness | noise | heating | other",
  "description": "string (max 500)",
  "status": "pending | in_progress | resolved",
  "priority": "high | medium | low",
  "imageUrl": "string | null",
  "adminRemarks": "string | null",
  "createdAt": "timestamp",
  "resolvedAt": "timestamp | null"
}
```

**Computed Fields:**
- `isOpen`: `status !== 'resolved'`
- `isPending`: `status === 'pending'`

**Indexes Required:**
- status (ASC), createdAt (DESC)
- studentId (ASC), createdAt (DESC)
- priority (DESC), status (ASC)
- determinedCategory (ASC), status (ASC)

---

### **Collection: `fees`**
**Document ID:** Auto-generated feeId
```json
{
  "feeId": "string",
  "studentId": "string",
  "studentName": "string",
  "amount": "number",
  "feeType": "room_rent | mess_fee | maintenance | other",
  "dueDate": "timestamp",
  "status": "pending | paid | overdue",
  "paidDate": "timestamp | null",
  "transactionId": "string | null",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Computed Fields:**
- `isPaid`: `status === 'paid'`
- `isOverdue`: `status !== 'paid' && dueDate < now()`

**Indexes Required:**
- studentId (ASC), status (ASC)
- status (ASC), dueDate (ASC)
- feeType (ASC), status (ASC)

---

### **Collection: `mess_menu`**
**Document ID:** Auto-generated or date-based menuId
```json
{
  "menuId": "string",
  "date": "timestamp",
  "breakfast": ["item1", "item2"],
  "lunch": ["item1", "item2", "item3"],
  "dinner": ["item1", "item2", "item3"],
  "remarks": "string | null",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Computed Fields:**
- `isToday`: `date.day === today.day`

**Indexes Required:**
- date (ASC/DESC)

---

### **Collection: `feedback`**
**Document ID:** Auto-generated feedbackId
```json
{
  "feedbackId": "string",
  "studentId": "string",
  "studentName": "string",
  "menuId": "string",
  "date": "timestamp",
  "mealType": "breakfast | lunch | dinner",
  "rating": "number (1-5)",
  "comment": "string | null (max 300)",
  "likedItems": ["item1", "item2"] | null,
  "dislikedItems": ["item1", "item2"] | null,
  "createdAt": "timestamp"
}
```

**Computed Fields:**
- `isPositive`: `rating >= 4`

**Indexes Required:**
- menuId (ASC), mealType (ASC)
- date (DESC), rating (DESC)
- studentId (ASC), date (DESC)

---

### **Collection: `chatbot_logs`**
**Document ID:** Auto-generated messageId
```json
{
  "messageId": "string",
  "studentId": "string",
  "message": "string",
  "response": "string",
  "detectedIntent": "complaint_status | fee_info | mess_menu | room_info | rules_regulations | maintenance | greeting | help | other",
  "keywords": ["keyword1", "keyword2"],
  "timestamp": "timestamp"
}
```

**Indexes Required:**
- studentId (ASC), timestamp (DESC)
- detectedIntent (ASC), timestamp (DESC)

---

## 🎯 Constants Reference

### **User Roles**
- `student`
- `admin`

### **Complaint Status**
- `pending` - New complaint, not yet addressed
- `in_progress` - Admin is working on it
- `resolved` - Complaint fixed

### **Complaint Priority**
- `high` - Urgent (electrical, water leaks, health hazards)
- `medium` - Important (AC, heating, noise)
- `low` - Can wait (general maintenance)

### **Complaint Categories**
- `plumbing` - Water issues, leaks, drainage
- `electrical` - Power, lights, outlets
- `maintenance` - General repairs
- `cleanliness` - Cleaning issues
- `noise` - Noise complaints
- `heating` - AC, heater issues
- `other` - Miscellaneous

### **Room Types**
- `single` - 1 bed
- `double` - 2 beds
- `triple` - 3 beds
- `quad` - 4 beds

### **Room Conditions**
- `good` - Well-maintained
- `fair` - Minor issues
- `needs_repair` - Requires maintenance

### **Fee Types**
- `room_rent` - Monthly room charges
- `mess_fee` - Monthly mess charges
- `maintenance` - Maintenance charges
- `other` - Other fees

### **Fee Status**
- `pending` - Not yet paid
- `paid` - Payment completed
- `overdue` - Past due date, not paid

### **Meal Types**
- `breakfast`
- `lunch`
- `dinner`

### **Chatbot Intents**
- `complaint_status` - Check complaint status
- `fee_info` - Fee information
- `mess_menu` - Today's menu
- `room_info` - Room details
- `rules_regulations` - Hostel rules
- `maintenance` - Maintenance help
- `greeting` - Hello, hi, etc.
- `help` - General help
- `other` - Unrecognized intent

### **Common Amenities**
- `wifi`
- `ac` (Air Conditioning)
- `attached_bathroom`
- `heater`
- `study_table`
- `wardrobe`
- `window`

---

## 📊 Firestore Query Examples

### **Get All Students**
```javascript
const studentsRef = db.collection('users').where('role', '==', 'student');
const snapshot = await studentsRef.get();
const students = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
```

### **Get Available Rooms**
```javascript
const roomsRef = db.collection('rooms')
  .where('currentOccupancy', '<', db.FieldValue.arrayUnion('capacity'));
const snapshot = await roomsRef.get();
```

### **Get Pending Complaints**
```javascript
const complaintsRef = db.collection('complaints')
  .where('status', '==', 'pending')
  .orderBy('createdAt', 'desc');
const snapshot = await complaintsRef.get();
```

### **Get Overdue Fees**
```javascript
const feesRef = db.collection('fees')
  .where('status', '==', 'pending')
  .where('dueDate', '<', new Date())
  .orderBy('dueDate', 'asc');
const snapshot = await feesRef.get();
```

### **Get Today's Menu**
```javascript
const today = new Date();
today.setHours(0, 0, 0, 0);
const tomorrow = new Date(today);
tomorrow.setDate(tomorrow.getDate() + 1);

const menuRef = db.collection('mess_menu')
  .where('date', '>=', today)
  .where('date', '<', tomorrow)
  .limit(1);
const snapshot = await menuRef.get();
const menu = snapshot.docs[0]?.data();
```

### **Get Feedback by Rating**
```javascript
const feedbackRef = db.collection('feedback')
  .where('rating', '>=', 4)
  .orderBy('rating', 'desc')
  .orderBy('createdAt', 'desc');
const snapshot = await feedbackRef.get();
```

---

## 🔐 Firebase Security Rules Quick Reference

```javascript
// Admin check function
function isAdmin() {
  return request.auth != null && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}

// User owns document
function isOwner(userId) {
  return request.auth.uid == userId;
}

// Apply to collections
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if isAdmin();
}

match /complaints/{complaintId} {
  allow read: if request.auth != null;
  allow create: if isOwner(request.resource.data.studentId);
  allow update, delete: if isAdmin();
}
```

---

## 📈 Aggregation Queries for Dashboard

### **Total Students Count**
```javascript
const studentsCount = await db.collection('users')
  .where('role', '==', 'student')
  .count()
  .get();
```

### **Complaint Statistics**
```javascript
const complaintsRef = db.collection('complaints');
const [pending, inProgress, resolved] = await Promise.all([
  complaintsRef.where('status', '==', 'pending').count().get(),
  complaintsRef.where('status', '==', 'in_progress').count().get(),
  complaintsRef.where('status', '==', 'resolved').count().get()
]);
```

### **Fee Collection Rate**
```javascript
const feesSnapshot = await db.collection('fees').get();
const fees = feesSnapshot.docs.map(doc => doc.data());

const totalAmount = fees.reduce((sum, fee) => sum + fee.amount, 0);
const paidAmount = fees
  .filter(fee => fee.status === 'paid')
  .reduce((sum, fee) => sum + fee.amount, 0);
const collectionRate = (paidAmount / totalAmount) * 100;
```

### **Average Mess Rating**
```javascript
const feedbackSnapshot = await db.collection('feedback').get();
const feedbacks = feedbackSnapshot.docs.map(doc => doc.data());
const avgRating = feedbacks.reduce((sum, f) => sum + f.rating, 0) / feedbacks.length;
```

---

## 🔄 Real-time Listeners

### **Listen to Pending Complaints**
```javascript
const unsubscribe = db.collection('complaints')
  .where('status', '==', 'pending')
  .onSnapshot((snapshot) => {
    const complaints = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    updateUI(complaints);
  });

// Clean up
unsubscribe();
```

### **Listen to New Feedback**
```javascript
const lastHour = new Date(Date.now() - 3600000);
const unsubscribe = db.collection('feedback')
  .where('createdAt', '>', lastHour)
  .orderBy('createdAt', 'desc')
  .onSnapshot((snapshot) => {
    snapshot.docChanges().forEach((change) => {
      if (change.type === 'added') {
        showNotification(change.doc.data());
      }
    });
  });
```

---

## 🗂️ Storage Paths

### **Complaint Images**
```
gs://your-bucket/complaint_images/{complaintId}/image.jpg
```

### **Profile Pictures**
```
gs://your-bucket/profile_pictures/{userId}/profile.jpg
```

### **Upload Example**
```javascript
const storageRef = storage.ref();
const fileRef = storageRef.child(`complaint_images/${complaintId}/${file.name}`);
const uploadTask = fileRef.put(file);

uploadTask.on('state_changed',
  (snapshot) => {
    const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
  },
  (error) => console.error(error),
  async () => {
    const downloadURL = await uploadTask.snapshot.ref.getDownloadURL();
    // Save downloadURL to Firestore
  }
);
```

---

## 📞 Utility Functions

### **Date Formatting**
```javascript
function formatDate(timestamp) {
  return timestamp.toDate().toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
}
```

### **Currency Formatting**
```javascript
function formatCurrency(amount) {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR'
  }).format(amount);
}
```

### **Status Badge Color**
```javascript
function getStatusColor(status) {
  const colors = {
    pending: 'orange',
    in_progress: 'blue',
    resolved: 'green',
    paid: 'green',
    overdue: 'red'
  };
  return colors[status] || 'gray';
}
```

---

**END OF REFERENCE**
