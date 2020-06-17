class RedmineDestinationBbsControllerController < ApplicationController
  unloadable
  def index

    # 日付を検索
    @search_params = destination_bbs_search_params

    # 日付欄が空欄の場合(初期表示時)は表示時点の日付データを取得する
    if @search_params.blank?
      @destination_bbs = RedmineDestinationBbsModel.where(registration_date: Date.today)
      @search_params_date = Date.today
      @search_params[:registration_date] = Date.today
    else
      @destination_bbs = RedmineDestinationBbsModel.search(@search_params)
      @search_params_date = @search_params[:registration_date]
    end
    # ユーザーID→名前変換用データ取得
    @users = User.select('id', 'lastname', 'firstname')
    # 登録用ユーザーIDの取得
    @user_id = User.current.attributes["id"]
    # 登録済レコードのID取得
    @destination_bbs_id = RedmineDestinationBbsModel.where(user_id: @user_id, registration_date: @search_params[:registration_date]).select('id')
  end

  def create
    @destination_bbs = RedmineDestinationBbsModel.new(params[:destination_bbs])
    @destination_bbs.user_id = params[:user_id]
    @destination_bbs.destination = params[:destination]
    # 年休ボタン押下時のみ当日以外の登録可能
    if params[:destination] == l(:button_holiday)
      @destination_bbs.registration_date = params[:registration_date]
    else
      @destination_bbs.registration_date = Date.today
      @destination_bbs.start_time = params[:start_time]
    end
    
    if @destination_bbs.save
      flash[:notice] = l(:notice_successful_create)
      redirect_back(fallback_location: {:controller => 'redmine_destination_bbs_controller', :action => 'index'})
    end
  end

  def update
    # コメント確認
    if params[:comment].present?
      @destination_bbs = RedmineDestinationBbsModel.where(user_id: params[:user_id], registration_date: params[:registration_date])
      # コメント更新時はコメントのみ更新
      if @destination_bbs.update(comment: params[:comment])
        flash[:notice] = l(:notice_successful_update)
        redirect_back(fallback_location: {:controller => 'redmine_destination_bbs_controller', :action => 'index'})
      end
    else
      # 行先確認(年休の場合当日以外も登録可)
      if params[:destination] == l(:button_holiday)
        @destination_bbs = RedmineDestinationBbsModel.where(user_id: params[:user_id], registration_date: params[:registration_date])
        destination_bbs = RedmineDestinationBbsModel.where(user_id: params[:user_id], registration_date: params[:registration_date]).first
      else
        # 年休以外の場合は当日のレコードのみ更新可
        @destination_bbs = RedmineDestinationBbsModel.where(user_id: params[:user_id], registration_date: Date.today)
        destination_bbs = RedmineDestinationBbsModel.where(user_id: params[:user_id], registration_date: Date.today).first
      end

      # コメント空欄時に更新ボタンを押した場合は何も更新しない
      if params[:destination].blank?
        redirect_back(fallback_location: {:controller => 'redmine_destination_bbs_controller', :action => 'index'})
      else
        # 退勤ボタンを押した時のみ終了時刻を更新
        if params[:end_time].present?
          if @destination_bbs.update(destination: params[:destination], end_time: params[:end_time])
            flash[:notice] = l(:notice_successful_update)
            redirect_back(fallback_location: {:controller => 'redmine_destination_bbs_controller', :action => 'index'})
          end
        elsif destination_bbs.start_time.blank? && params[:destination] != l(:button_holiday)
          if @destination_bbs.update(destination: params[:destination], start_time: Time.zone.now)
            flash[:notice] = l(:notice_successful_update)
            redirect_back(fallback_location: {:controller => 'redmine_destination_bbs_controller', :action => 'index'})
          end
        else
          if @destination_bbs.update(destination: params[:destination])
            flash[:notice] = l(:notice_successful_update)
            redirect_back(fallback_location: {:controller => 'redmine_destination_bbs_controller', :action => 'index'})
          end
        end
      end
    end
  end

  private

  # 日付指定時の検索用関数
  def destination_bbs_search_params
    params.fetch(:search, {}).permit(:registration_date)
  end

end
