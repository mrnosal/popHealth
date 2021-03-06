class MeasuresController < ApplicationController
  before_filter :set_up_executor
  
  def index
    @selected_measures = mongo['selected_measures'].find().to_a #need to call to_a so that it isn't a cursor
    @grouped_selected_measures = @selected_measures.group_by {|measure| measure['category']}
    @categories = Measure.all_by_category

    render 'dashboard'
  end
    
  def result
    @result = @executor.measure_result(params[:id], params[:sub_id], :effective_date=>Time.gm(2010, 9, 19).to_i)
    
    render :json => @result
  end

  def definition
    @definition = @executor.measure_def(params[:id], params[:sub_id])
    
    render :json => @definition
  end

  def show
    @definition = @executor.measure_def(params[:id], params[:sub_id])
    
    render 'measure'
  end
  
  def patients
    @result = @executor.measure_result(params[:id], params[:sub_id], :effective_date=>Time.gm(2010, 9, 19).to_i)
    @definition = @executor.measure_def(params[:id], params[:sub_id])
    
    @numerator = mongo['records'].find('_id' => {'$in' => @result[:numerator_members]})
    @anti_numerator = mongo['records'].find('_id' => {'$in' => @result[:antinumerator_members]})
  end
  
  def select
    measure = Measure.add_measure(params[:id])
    
    results = {:patient_count => mongo['records'].count}
    if measure['subs'].empty?
      results[measure['id']] = @executor.measure_result(params[:id], nil, :effective_date=>Time.gm(2010, 9, 19).to_i)
    else
      measure['subs'].each do |sub_id|
        results[measure['id'] + sub_id] = @executor.measure_result(params[:id], sub_id, :effective_date=>Time.gm(2010, 9, 19).to_i)
      end
    end
    
    render :partial => 'measure_stats', :locals => {:measure => measure, :results => results}
  end
  
  def remove
    Measure.remove_measure(params[:id])
    render :text => 'Removed'
  end

  private
  
  def set_up_executor
    @executor = QME::MapReduce::Executor.new(mongo)
    @patient_count = mongo['records'].count
  end

end
