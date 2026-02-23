# Gemini API Setup Guide

## 🚀 Quick Start

### Step 1: Get Your Free Gemini API Key

1. Visit **Google AI Studio**: https://makersuite.google.com/app/apikey
2. Sign in with your Google account
3. Click **"Get API Key"** or **"Create API Key"**
4. Select **"Create API key in new project"** (or select existing project)
5. Copy your API key (it starts with `AIza...`)

**⚠️ Important:** Keep your API key private and secure!

---

### Step 2: Add API Key to the App

#### **Method 1: Through the App (Recommended)**
1. Open the HostelAssist mobile app
2. Login as a student
3. Navigate to the **Chat** tab (💬 icon)
4. Click the **⚙️ Settings icon** in the top-right corner
5. Paste your API key in the text field
6. Click **Save**
7. Start chatting!

#### **Method 2: Direct in Shared Preferences (Advanced)**
```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> setApiKey(String apiKey) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('gemini_api_key', apiKey);
}
```

---

### Step 3: Test the Chatbot

Try these sample questions:

```
1. "Hello! How can you help me?"
2. "What's today's mess menu?"
3. "How do I submit a complaint?"
4. "Tell me about hostel fees"
5. "What are the room types available?"
```

---

## 🔧 API Configuration Details

### **Gemini Model Used:**
- `gemini-pro` - Text-only model optimized for conversations

### **API Endpoint:**
```
https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent
```

### **Generation Parameters:**
```json
{
  "temperature": 0.7,      // Balanced creativity
  "maxOutputTokens": 256,  // ~150-200 words
  "topP": 0.8,
  "topK": 40
}
```

### **Safety Settings:**
All safety categories set to `BLOCK_MEDIUM_AND_ABOVE`:
- Harassment
- Hate Speech
- Sexually Explicit Content
- Dangerous Content

---

## 📊 API Limits & Pricing

### **Free Tier (As of Feb 2026):**
- ✅ **60 requests per minute**
- ✅ **1,500 requests per day**
- ✅ **No credit card required**

### **Rate Limits:**
If you exceed the limit, you'll see:
> "Too many requests. Please wait a moment and try again."

**Solution:** Wait 60 seconds and retry.

---

## 🛡️ Security Best Practices

### **DO:**
✅ Keep your API key private  
✅ Store it securely in the app  
✅ Use environment variables for development  
✅ Regenerate if compromised  

### **DON'T:**
❌ Share your API key publicly  
❌ Commit it to version control (add to `.gitignore`)  
❌ Expose it in client-side code (except in encrypted storage)  
❌ Use the same key across multiple apps  

---

## 🔄 API Key Management

### **To Update API Key:**
1. Open Chat tab
2. Click ⚙️ Settings
3. Clear the old key (optional)
4. Enter new key
5. Save

### **To Remove API Key:**
1. Open Chat tab
2. Click ⚙️ Settings
3. Click **Clear** button
4. Confirm

### **To Check if API Key is Set:**
```dart
final geminiService = GeminiService();
await geminiService.initialize();
print('API Key configured: ${geminiService.isConfigured}');
```

---

## 🐛 Troubleshooting

### **Problem: "Please configure your Gemini API key"**
**Solution:** API key not set. Follow Step 2 above.

### **Problem: "Invalid API key"**
**Solutions:**
- Verify the key is correct (no extra spaces)
- Ensure the key starts with `AIza`
- Check if the key is enabled in Google Cloud Console
- Regenerate the key if necessary

### **Problem: "Too many requests"**
**Solution:** Wait 60 seconds. Free tier has rate limits.

### **Problem: "Couldn't connect to the AI service"**
**Solutions:**
- Check internet connection
- Verify firewall/proxy settings
- Ensure HTTPS is allowed
- Try again later

### **Problem: "No response generated"**
**Solutions:**
- Try rephrasing your question
- Keep questions concise
- Avoid restricted content
- Check API quota

---

## 📱 Using in Development

### **For Testing (Don't use in production!):**

You can hardcode the API key temporarily:

```dart
// lib/services/gemini_service.dart

class GeminiService {
  static const String _developmentApiKey = 'AIzaSyXXXXXXXXXXXXXXXXXX'; // DEV ONLY
  
  String? _apiKey;
  
  Future<void> initialize() async {
    #if DEBUG
    _apiKey = _developmentApiKey; // Auto-use in development
    #else
    _apiKey = await getApiKey(); // Use saved key in production
    #endif
  }
}
```

**⚠️ Remember to remove before committing!**

---

## 🌐 Alternative: Environment Variables

### **Method 1: Using flutter_dotenv**

1. Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. Create `.env` file:
```
GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXX
```

3. Add to `.gitignore`:
```
.env
```

4. Load in main.dart:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

5. Use in code:
```dart
final apiKey = dotenv.env['GEMINI_API_KEY'];
```

---

## 📖 API Documentation

### **Official Docs:**
- Gemini API: https://ai.google.dev/docs
- API Reference: https://ai.google.dev/api
- Pricing: https://ai.google.dev/pricing
- Quickstart: https://ai.google.dev/tutorials/quickstart

### **Community Resources:**
- Stack Overflow: https://stackoverflow.com/questions/tagged/gemini-api
- Discord: https://discord.gg/google-ai
- Examples: https://github.com/google/generative-ai-dart

---

## 🎓 Example Conversations

### **Example 1: Complaint Help**
**Student:** "How do I report a broken tap?"  
**AI:** "You can submit a complaint through the Complaints tab! Here's how:
1. Tap the Complaints icon
2. Click 'New Complaint'
3. Select 'Plumbing' category
4. Describe the issue (e.g., 'Broken tap in bathroom')
5. Add a photo if possible
6. Submit!

The admin will review and assign priority based on urgency."

### **Example 2: Mess Menu**
**Student:** "What's for lunch today?"  
**AI:** "To check today's mess menu:
1. Go to the Mess tab (🍽️ icon)
2. View the complete menu for Breakfast, Lunch, and Dinner

You can also provide feedback after meals to help improve the menu!"

### **Example 3: Fee Inquiry**
**Student:** "When is my room rent due?"  
**AI:** "You can check your fee details in the Fees tab (💰 icon). It will show:
- Fee type (Room Rent, Mess Fee, etc.)
- Amount due
- Due date
- Payment status

Make sure to pay before the due date to avoid late fees!"

---

## 🚀 Advanced Features

### **Custom Context:**
The chatbot can provide context-aware responses based on the student's data:

```dart
final context = await geminiService.getHostelContext(
  studentId: user.uid,
  intent: 'complaint_status', // or fee_info, mess_menu, etc.
);

final response = await geminiService.sendMessage(
  message: userMessage,
  context: context,
);
```

### **Intent Detection:**
Simple keyword-based intent detection:
- `complaint` → Complaint Status
- `fee`/`payment` → Fee Information
- `menu`/`food` → Mess Menu
- `room` → Room Information
- `rule` → Rules & Regulations

---

## ✅ Checklist

Before deploying to production:

- [ ] API key is stored securely
- [ ] No hardcoded keys in source code
- [ ] `.env` file is in `.gitignore`
- [ ] Error handling implemented
- [ ] Rate limiting considered
- [ ] User feedback for errors
- [ ] Loading states shown
- [ ] Fallback responses ready
- [ ] API quota monitored
- [ ] Security best practices followed

---

## 📞 Support

### **Need Help?**
- Check the troubleshooting section above
- Review Gemini API documentation
- Test with sample questions
- Verify API key is correct
- Check internet connection

### **Report Issues:**
- App issues: Contact hostel admin
- API issues: Check Google AI Studio status
- Billing: Visit Google Cloud Console

---

**Last Updated:** February 23, 2026  
**Gemini API Version:** v1beta  
**Model:** gemini-pro
