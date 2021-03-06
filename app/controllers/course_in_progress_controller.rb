class CourseInProgressController < ApplicationController
    before_action :set_initial_params, only: [:index, :next]

    def index
        @course = Course.find(params[:course_id])
    end

    def next
        already_changed = false

        @topics.each_with_index do |topic, index|
            if !already_changed
                topic.lessons.each_with_index do |lesson, key|
                    if lesson.id == @actual_lesson.id
                        if topic.lessons[key + 1]
                            @course_progress.lesson_id = topic.lessons[key + 1].id
                            @course_progress.save
                            
                            already_changed = true
                        else
                            if @topics[index + 1]
                                @actual_topic = @topics[index + 1]

                                @actual_lesson = @actual_topic.lessons[0]

                                @course_progress.topic_id = @actual_topic.id
                                @course_progress.lesson_id = @actual_lesson.id

                                @course_progress.save

                                already_changed = true
                            else
                                @course_progress.course_ended = true

                                @course_progress.save
                                already_changed = true
                            end
                        end
                    end
                end
            end
        end

        redirect_to play_course_path, :params => params
    end

    def certificate

        @course = Course.find(params[:course_id])
        @user = current_user

        respond_to do |format|
            format.html
            format.pdf do
                render pdf: "certificate",
                        template: "course_in_progress/certificate.html.erb"   # Excluding ".pdf" extension.
            end
        end
    end

    private
        def set_initial_params
            @topics = Topic.includes(:lessons, :course).references(:lessons)
                .where(course_id: params[:course_id])

            @course_users = CourseUser.where(course_id: params[:course_id], user_id: current_user.id)
            @course_progress = CourseProgress.where(course_user_id: @course_users).first

            @actual_topic = Topic.find(@course_progress.topic_id)
            @actual_lesson = Lesson.find(@course_progress.lesson_id)
        end
end
