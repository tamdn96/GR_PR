class Trainee::ExamLessonsController < ApplicationController
  layout "exam", except: :index
  load_and_authorize_resource param_method: :params_exam_lesson
  before_action :load_course_user_and_lesson, only: :new

  def new
    @exam_lesson = ExamLesson.new course_user_id: @course_user.id, lesson_id: @lesson.id
    questions = @lesson.questions.get_random.limit 20
    @list_question_answers = Array.new
    questions.each do |qs|
      @list_question_answers.push ListQuestionAnswer.new question_id: qs.id
    end
  end

  def index
  end

  def create
    if @exam_lesson.save
      cal_score
      def_result @score
      @exam_lesson.update_attributes score: @score, result: @result
      do_change_status_course_user_lesson(@exam_lesson)
      flash[:success]= "Chúc mừng bạn đã hoàn thành bài kiểm tra"
      redirect_to trainee_exam_lesson_path(@exam_lesson)
    else
      flash[:danger] = "Không thể hoàn thành bài kiểm tra"
      render :new
    end
  end

  def show
    @list_question_answers = @exam_lesson.list_question_answers
  end

  private

  def load_course_user_and_lesson
    cul = CourseUserLesson.find_by id: params[:course_user_lesson_id]
    if cul
      @course_user = cul.course_user
      @lesson = cul.lesson
    else
      flash[:danger] = "Không tìm thấy liên kết"
      redirect_to root_path
    end
  end

  def params_exam_lesson
    params.require(:exam_lesson).permit :lesson_id, :course_user_id,
      list_question_answers_attributes: [:question_id, {:answer_ids => []}, :chosen_id, :exam_lesson_id]
  end

  def cal_score
    answers = eval params[:exam_lesson][:list_question_answers_attributes].to_s
    @count_true = 0
    answers.each do |answer|
      ans = Answer.find_by(id: answer[1]["chosen_id"])
      next if ans.nil?
      if ans.true?
        @count_true+=1
      end
    end
    @score = ( @count_true.to_f / answers.length.to_f) * 100
  end

  def def_result score
    if score >= 60
      @result = "pass"
    else
      @result = "fail"
    end
  end

  def do_change_status_course_user_lesson exam_lesson
    cu = exam_lesson.course_user
    ls = exam_lesson.lesson
    course_user_lesson = CourseUserLesson.find_by course_user_id: cu.id, lesson_id: ls.id
    if exam_lesson.pass?
      course_user_lesson.update_attributes status: "finish", date_end: Time.zone.now
    else
      if cu.exam_lessons.of_lesson(ls.id).length >=3
        course_user_lesson.update_attributes status: "finish_fail", date_end: Time.zone.now
      end
    end
  end
end
