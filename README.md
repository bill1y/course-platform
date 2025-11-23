# 🎓 Course Platform

A modern, full-featured online learning platform with interactive quizzes, progress tracking, and grade reporting.

![Course Platform](https://img.shields.io/badge/Next.js-14-black?style=for-the-badge&logo=next.js)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green?style=for-the-badge&logo=supabase)
![TypeScript](https://img.shields.io/badge/TypeScript-5-blue?style=for-the-badge&logo=typescript)
![Tailwind](https://img.shields.io/badge/Tailwind-CSS-38bdf8?style=for-the-badge&logo=tailwind-css)

## ✨ Features

- 🎯 **Interactive Quizzes** - Multiple choice, true/false, short answer, and essay questions
- 📊 **Progress Tracking** - Real-time student progress and completion tracking
- 🎓 **Auto-Grading** - Instant feedback on quiz submissions
- 📈 **Grade Reports** - Comprehensive analytics and reporting for students and instructors
- 👥 **User Management** - Student and instructor roles with authentication
- 📱 **Responsive Design** - Works perfectly on desktop, tablet, and mobile
- 🔒 **Secure** - Built with Supabase Row Level Security (RLS)
- ⚡ **Fast** - Serverless architecture with Next.js and Supabase

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ installed
- A Supabase account (free tier works great!)
- Git installed

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/course-platform.git
cd course-platform
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Set Up Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Run the database schema:
   - Go to SQL Editor in Supabase
   - Copy contents of `database/supabase_schema.sql`
   - Execute the SQL

### 4. Configure Environment Variables

Create a `.env.local` file in the root directory:

```env
NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

Get these values from Supabase Dashboard → Settings → API

### 5. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser!

## 📚 Documentation

- **[Setup Guide](SETUP_GUIDE.md)** - Detailed setup instructions
- **[Complete Overview](COMPLETE_OVERVIEW.md)** - Full feature documentation
- **[Quick Start](QUICK_START.txt)** - 30-minute quick start guide

## 🏗️ Project Structure

```
course-platform/
├── app/                    # Next.js app directory
│   ├── api/               # API routes (serverless functions)
│   ├── dashboard/         # Student dashboard
│   ├── courses/           # Course pages
│   └── page.tsx          # Landing page
├── components/            # React components
├── contexts/              # React contexts (Auth, etc.)
├── lib/                   # Utility functions & Supabase client
├── database/              # Database schema
├── public/                # Static assets
└── docs/                  # Documentation

```

## 🛠️ Built With

- **[Next.js 14](https://nextjs.org/)** - React framework
- **[Supabase](https://supabase.com/)** - Backend as a Service (PostgreSQL, Auth, Storage)
- **[TypeScript](https://www.typescriptlang.org/)** - Type safety
- **[Tailwind CSS](https://tailwindcss.com/)** - Styling
- **[Chart.js](https://www.chartjs.org/)** - Data visualization
- **[Vercel](https://vercel.com/)** - Deployment

## 🚀 Deployment

### Deploy to Vercel (Recommended)

1. Push your code to GitHub
2. Import your repository on [Vercel](https://vercel.com)
3. Add environment variables
4. Deploy!

Detailed deployment guide: [SETUP_GUIDE.md](SETUP_GUIDE.md)

## 📊 Database Schema

The platform uses PostgreSQL (via Supabase) with the following main tables:

- `profiles` - User profiles (extends Supabase auth)
- `courses` - Course information
- `modules` - Course modules
- `lessons` - Individual lessons
- `quizzes` - Quiz definitions
- `questions` - Quiz questions
- `answer_options` - Multiple choice options
- `enrollments` - Student course enrollments
- `quiz_attempts` - Student quiz attempts
- `student_answers` - Student answers to questions
- `lesson_progress` - Lesson completion tracking

See `database/supabase_schema.sql` for the complete schema.

## 🔒 Security

- **Row Level Security (RLS)** enabled on all tables
- **JWT Authentication** via Supabase Auth
- **Role-based access control** (student, instructor, admin)
- **Secure API routes** with authentication checks
- **Environment variables** for sensitive data

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with the amazing [Supabase](https://supabase.com/) platform
- UI components inspired by modern education platforms
- Icons from [Lucide](https://lucide.dev/)

## 📞 Support

- 📚 Documentation: Check the `docs/` folder
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/course-platform/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/course-platform/discussions)

## 🗺️ Roadmap

- [ ] Video lesson support
- [ ] Live class integration (Zoom/Google Meet)
- [ ] Discussion forums
- [ ] Certificate generation
- [ ] Payment integration (Stripe)
- [ ] Mobile app (React Native)
- [ ] AI-powered quiz generation
- [ ] Peer review assignments

---

**Made with ❤️ by developers, for learners**

⭐ Star this repo if you find it helpful!
