-- ============================================
-- COURSE PLATFORM SCHEMA FOR SUPABASE
-- ============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USER PROFILES (extends Supabase auth.users)
-- ============================================

CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    role TEXT DEFAULT 'student' CHECK (role IN ('student', 'instructor', 'admin')),
    profile_image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING (true);

CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- ============================================
-- COURSES
-- ============================================

CREATE TABLE public.courses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    instructor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    thumbnail_url TEXT,
    is_published BOOLEAN DEFAULT false,
    price DECIMAL(10,2) DEFAULT 0.00,
    passing_grade INTEGER DEFAULT 70,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    estimated_duration INTEGER
);

ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

-- Policies for courses
CREATE POLICY "Published courses are viewable by everyone"
    ON public.courses FOR SELECT
    USING (is_published = true OR instructor_id = auth.uid());

CREATE POLICY "Instructors can insert courses"
    ON public.courses FOR INSERT
    WITH CHECK (auth.uid() = instructor_id);

CREATE POLICY "Instructors can update own courses"
    ON public.courses FOR UPDATE
    USING (auth.uid() = instructor_id);

CREATE POLICY "Instructors can delete own courses"
    ON public.courses FOR DELETE
    USING (auth.uid() = instructor_id);

-- ============================================
-- MODULES
-- ============================================

CREATE TABLE public.modules (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    order_index INTEGER NOT NULL,
    is_published BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.modules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Modules viewable if course is accessible"
    ON public.modules FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.courses
            WHERE courses.id = modules.course_id
            AND (courses.is_published = true OR courses.instructor_id = auth.uid())
        )
    );

CREATE POLICY "Instructors can manage modules in their courses"
    ON public.modules FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.courses
            WHERE courses.id = modules.course_id
            AND courses.instructor_id = auth.uid()
        )
    );

-- ============================================
-- LESSONS
-- ============================================

CREATE TABLE public.lessons (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    module_id UUID REFERENCES public.modules(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    content_type TEXT NOT NULL CHECK (content_type IN ('text', 'video', 'pdf', 'quiz')),
    content TEXT,
    video_url TEXT,
    pdf_url TEXT,
    order_index INTEGER NOT NULL,
    duration INTEGER,
    is_free_preview BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lessons viewable if module is accessible"
    ON public.lessons FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.modules
            JOIN public.courses ON modules.course_id = courses.id
            WHERE modules.id = lessons.module_id
            AND (courses.is_published = true OR courses.instructor_id = auth.uid() OR lessons.is_free_preview = true)
        )
    );

CREATE POLICY "Instructors can manage lessons"
    ON public.lessons FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.modules
            JOIN public.courses ON modules.course_id = courses.id
            WHERE modules.id = lessons.module_id
            AND courses.instructor_id = auth.uid()
        )
    );

-- ============================================
-- QUIZZES
-- ============================================

CREATE TABLE public.quizzes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    lesson_id UUID REFERENCES public.lessons(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    time_limit INTEGER,
    passing_score INTEGER DEFAULT 70,
    max_attempts INTEGER DEFAULT 3,
    randomize_questions BOOLEAN DEFAULT false,
    show_answers_after BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Quizzes viewable if lesson is accessible"
    ON public.quizzes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.lessons
            JOIN public.modules ON lessons.module_id = modules.id
            JOIN public.courses ON modules.course_id = courses.id
            WHERE lessons.id = quizzes.lesson_id
            AND (courses.is_published = true OR courses.instructor_id = auth.uid())
        )
    );

CREATE POLICY "Instructors can manage quizzes"
    ON public.quizzes FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.lessons
            JOIN public.modules ON lessons.module_id = modules.id
            JOIN public.courses ON modules.course_id = courses.id
            WHERE lessons.id = quizzes.lesson_id
            AND courses.instructor_id = auth.uid()
        )
    );

-- ============================================
-- QUESTIONS
-- ============================================

CREATE TABLE public.questions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    quiz_id UUID REFERENCES public.quizzes(id) ON DELETE CASCADE NOT NULL,
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK (question_type IN ('multiple_choice', 'true_false', 'short_answer', 'essay')),
    points INTEGER DEFAULT 1,
    order_index INTEGER,
    explanation TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Questions viewable if quiz is accessible"
    ON public.questions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.quizzes
            JOIN public.lessons ON quizzes.lesson_id = lessons.id
            JOIN public.modules ON lessons.module_id = modules.id
            JOIN public.courses ON modules.course_id = courses.id
            WHERE quizzes.id = questions.quiz_id
            AND (courses.is_published = true OR courses.instructor_id = auth.uid())
        )
    );

CREATE POLICY "Instructors can manage questions"
    ON public.questions FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.quizzes
            JOIN public.lessons ON quizzes.lesson_id = lessons.id
            JOIN public.modules ON lessons.module_id = modules.id
            JOIN public.courses ON modules.course_id = courses.id
            WHERE quizzes.id = questions.quiz_id
            AND courses.instructor_id = auth.uid()
        )
    );

-- ============================================
-- ANSWER OPTIONS
-- ============================================

CREATE TABLE public.answer_options (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    question_id UUID REFERENCES public.questions(id) ON DELETE CASCADE NOT NULL,
    option_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT false,
    order_index INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.answer_options ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Answer options viewable if question is accessible"
    ON public.answer_options FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.questions
            WHERE questions.id = answer_options.question_id
        )
    );

CREATE POLICY "Instructors can manage answer options"
    ON public.answer_options FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.questions
            JOIN public.quizzes ON questions.quiz_id = quizzes.id
            JOIN public.lessons ON quizzes.lesson_id = lessons.id
            JOIN public.modules ON lessons.module_id = modules.id
            JOIN public.courses ON modules.course_id = courses.id
            WHERE questions.id = answer_options.question_id
            AND courses.instructor_id = auth.uid()
        )
    );

-- ============================================
-- ENROLLMENTS
-- ============================================

CREATE TABLE public.enrollments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE NOT NULL,
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    current_module_id UUID REFERENCES public.modules(id) ON DELETE SET NULL,
    current_lesson_id UUID REFERENCES public.lessons(id) ON DELETE SET NULL,
    UNIQUE(user_id, course_id)
);

ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own enrollments"
    ON public.enrollments FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own enrollments"
    ON public.enrollments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Instructors can view enrollments in their courses"
    ON public.enrollments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.courses
            WHERE courses.id = enrollments.course_id
            AND courses.instructor_id = auth.uid()
        )
    );

-- ============================================
-- LESSON PROGRESS
-- ============================================

CREATE TABLE public.lesson_progress (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    enrollment_id UUID REFERENCES public.enrollments(id) ON DELETE CASCADE NOT NULL,
    lesson_id UUID REFERENCES public.lessons(id) ON DELETE CASCADE NOT NULL,
    status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    time_spent INTEGER DEFAULT 0,
    UNIQUE(enrollment_id, lesson_id)
);

ALTER TABLE public.lesson_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own lesson progress"
    ON public.lesson_progress FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.enrollments
            WHERE enrollments.id = lesson_progress.enrollment_id
            AND enrollments.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage own lesson progress"
    ON public.lesson_progress FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.enrollments
            WHERE enrollments.id = lesson_progress.enrollment_id
            AND enrollments.user_id = auth.uid()
        )
    );

-- ============================================
-- QUIZ ATTEMPTS
-- ============================================

CREATE TABLE public.quiz_attempts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    enrollment_id UUID REFERENCES public.enrollments(id) ON DELETE CASCADE NOT NULL,
    quiz_id UUID REFERENCES public.quizzes(id) ON DELETE CASCADE NOT NULL,
    attempt_number INTEGER DEFAULT 1,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    submitted_at TIMESTAMPTZ,
    score DECIMAL(5,2),
    points_earned INTEGER,
    points_possible INTEGER,
    passed BOOLEAN,
    time_taken INTEGER,
    status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'submitted', 'graded'))
);

ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own quiz attempts"
    ON public.quiz_attempts FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.enrollments
            WHERE enrollments.id = quiz_attempts.enrollment_id
            AND enrollments.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage own quiz attempts"
    ON public.quiz_attempts FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.enrollments
            WHERE enrollments.id = quiz_attempts.enrollment_id
            AND enrollments.user_id = auth.uid()
        )
    );

CREATE POLICY "Instructors can view quiz attempts in their courses"
    ON public.quiz_attempts FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.enrollments
            JOIN public.courses ON enrollments.course_id = courses.id
            WHERE enrollments.id = quiz_attempts.enrollment_id
            AND courses.instructor_id = auth.uid()
        )
    );

-- ============================================
-- STUDENT ANSWERS
-- ============================================

CREATE TABLE public.student_answers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    quiz_attempt_id UUID REFERENCES public.quiz_attempts(id) ON DELETE CASCADE NOT NULL,
    question_id UUID REFERENCES public.questions(id) ON DELETE CASCADE NOT NULL,
    answer_option_id UUID REFERENCES public.answer_options(id) ON DELETE SET NULL,
    answer_text TEXT,
    is_correct BOOLEAN,
    points_earned INTEGER DEFAULT 0,
    graded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    graded_at TIMESTAMPTZ,
    feedback TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.student_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own answers"
    ON public.student_answers FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.quiz_attempts
            JOIN public.enrollments ON quiz_attempts.enrollment_id = enrollments.id
            WHERE quiz_attempts.id = student_answers.quiz_attempt_id
            AND enrollments.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage own answers"
    ON public.student_answers FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.quiz_attempts
            JOIN public.enrollments ON quiz_attempts.enrollment_id = enrollments.id
            WHERE quiz_attempts.id = student_answers.quiz_attempt_id
            AND enrollments.user_id = auth.uid()
        )
    );

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to calculate quiz score
CREATE OR REPLACE FUNCTION calculate_quiz_score(attempt_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    total_points INTEGER;
    earned_points INTEGER;
    score DECIMAL;
BEGIN
    SELECT 
        SUM(q.points),
        SUM(sa.points_earned)
    INTO total_points, earned_points
    FROM student_answers sa
    JOIN questions q ON sa.question_id = q.id
    WHERE sa.quiz_attempt_id = attempt_id;
    
    IF total_points > 0 THEN
        score := (earned_points::DECIMAL / total_points * 100);
    ELSE
        score := 0;
    END IF;
    
    RETURN ROUND(score, 2);
END;
$$ LANGUAGE plpgsql;

-- Function to update course progress
CREATE OR REPLACE FUNCTION update_course_progress(enrollment_id_param UUID)
RETURNS VOID AS $$
DECLARE
    total_lessons INTEGER;
    completed_lessons INTEGER;
    progress DECIMAL;
BEGIN
    SELECT COUNT(l.id) INTO total_lessons
    FROM lessons l
    JOIN modules m ON l.module_id = m.id
    JOIN courses c ON m.course_id = c.id
    JOIN enrollments e ON c.id = e.course_id
    WHERE e.id = enrollment_id_param;
    
    SELECT COUNT(lp.id) INTO completed_lessons
    FROM lesson_progress lp
    WHERE lp.enrollment_id = enrollment_id_param 
    AND lp.status = 'completed';
    
    IF total_lessons > 0 THEN
        progress := (completed_lessons::DECIMAL / total_lessons * 100);
    ELSE
        progress := 0;
    END IF;
    
    UPDATE enrollments 
    SET progress_percentage = ROUND(progress, 2)
    WHERE id = enrollment_id_param;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_courses_updated_at
    BEFORE UPDATE ON public.courses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_modules_updated_at
    BEFORE UPDATE ON public.modules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lessons_updated_at
    BEFORE UPDATE ON public.lessons
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SAMPLE DATA
-- ============================================

-- Note: Users are managed by Supabase Auth
-- After a user signs up, a profile is automatically created via trigger

-- Create trigger to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, first_name, last_name)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'first_name',
        NEW.raw_user_meta_data->>'last_name'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_courses_instructor ON public.courses(instructor_id);
CREATE INDEX idx_courses_published ON public.courses(is_published);
CREATE INDEX idx_modules_course ON public.modules(course_id);
CREATE INDEX idx_lessons_module ON public.lessons(module_id);
CREATE INDEX idx_quizzes_lesson ON public.quizzes(lesson_id);
CREATE INDEX idx_questions_quiz ON public.questions(quiz_id);
CREATE INDEX idx_answer_options_question ON public.answer_options(question_id);
CREATE INDEX idx_enrollments_user ON public.enrollments(user_id);
CREATE INDEX idx_enrollments_course ON public.enrollments(course_id);
CREATE INDEX idx_lesson_progress_enrollment ON public.lesson_progress(enrollment_id);
CREATE INDEX idx_quiz_attempts_enrollment ON public.quiz_attempts(enrollment_id);
CREATE INDEX idx_quiz_attempts_quiz ON public.quiz_attempts(quiz_id);
CREATE INDEX idx_student_answers_attempt ON public.student_answers(quiz_attempt_id);
