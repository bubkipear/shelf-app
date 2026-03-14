# 🗂️ Shelf - Life Experiments Tracker

> Your life experiments, beautifully organized on cozy room shelves

Shelf is an iOS app that turns life experiments into photorealistic objects sitting on virtual shelves in a cozy room setting. Track habits, try new behaviors, and share your journey with a community of fellow experimenters.

## ✨ Features

### 🏠 Cozy Room Aesthetic
- Beautiful room corner with window, curtains, and sleeping cat
- Multiple art styles: Korean minimal, gouache painting, hand-drawn lines
- Photorealistic sticker objects with iOS background removal
- Subtle animations (curtain sway, cat breathing)

### 🧪 Experiment Tracking  
- Visual object-based representation of experiments
- Automatic state changes: Tended → Neglected → Adrift → Abandoned
- Custom photos or preset icons for each experiment
- Check-in tracking with streaks and progress

### 🌐 Social Features
- Browse community experiments for inspiration
- "Try This" to copy experiments to your shelf
- Like and share experiments publicly
- Discover what others are trying

### 💳 Freemium Model
- 3 free experiments for all users
- Premium: Unlimited experiments + all art styles
- Offline-first with cloud sync when authenticated

## 🛠️ Technical Stack

- **Frontend**: SwiftUI, iOS 15+
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Payments**: RevenueCat for subscription management
- **Image Processing**: iOS VisionKit for background removal
- **Architecture**: Offline-first with cloud sync

## 🚀 Getting Started

### Prerequisites
- Xcode 15+
- iOS 15+ device/simulator  
- Supabase account
- RevenueCat account (for premium features)

### Setup

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd cosmos-app
   ```

2. **Set up Supabase**
   - Create account at https://supabase.com
   - Create new project named "shelf-app"
   - Run SQL schema from `supabase-schema.sql`
   - Get Project URL and anon key
   - Update `SupabaseService.swift` with your credentials

3. **Install dependencies**
   - Open `Cosmos.xcodeproj` in Xcode
   - Dependencies should auto-resolve via Swift Package Manager
   - Add Supabase SDK and RevenueCat if needed

4. **Run the app**
   - Select target device/simulator
   - Build and run (⌘+R)

## 📁 Project Structure

```
├── Cosmos/
│   ├── Models/          # Data models (Experiment, CheckIn, etc.)
│   ├── Views/           # SwiftUI views (Shelf, Auth, Social, etc.)
│   ├── Stores/          # Data management (Local + Supabase sync)
│   └── Services/        # Backend integration (Supabase API)
├── supabase-schema.sql  # Database schema
├── SETUP-GUIDE.md       # Detailed setup instructions
└── Package.swift        # Swift Package Manager dependencies
```

## 🎨 Key Views

- **MyShelfView**: Main shelf interface with cozy room background
- **AuthView**: Beautiful sign-up/sign-in with offline fallback  
- **SocialFeedView**: Community experiments discovery
- **NewExperimentView**: Add experiment flow with photo capture
- **ExperimentDetailView**: Individual experiment tracking

## 📱 Screenshots

*(Add screenshots here once UI is finalized)*

## 🚢 Deployment

### TestFlight
1. Set up App Store Connect
2. Configure build settings
3. Archive and upload build
4. Submit for review

### Production
- Ensure Supabase is on paid plan for scaling
- Configure RevenueCat webhook URLs
- Set up analytics and crash reporting
- Monitor performance and costs

## 🤝 Contributing

This is a personal project, but feedback and suggestions are welcome!

## 📄 License

Private project - All rights reserved

---

**Built with ❤️ using SwiftUI and Supabase**