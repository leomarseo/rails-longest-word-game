require 'open-uri'
require 'json'

class GamesController < ApplicationController
  def new
    @grid = generate_grid(10)
    @time = Time.now.strftime('%M:%S')
  end

  def score
    @suggestion = params[:suggestion]
    @grid = params[:grid]
    @time_taken = calculate_seconds(params[:time])
    result = calculate_result(@suggestion, @grid, @time_taken)
    @score = result[:score]
    @message = result[:message]
  end

  private

  def generate_grid(grid_size)
    grid = []
    grid_size.times { grid << ('a'..'z').to_a.sample }
    grid
  end

  def calculate_seconds(time_before)
    seconds_before = time_before.chars.first(2).join.to_i * 60 + time_before.chars.last(2).join.to_i
    seconds_now = Time.now.strftime('%M:%S').chars.first(2).join.to_i * 60 + Time.now.strftime('%M:%S').chars.last(2).join.to_i
    seconds_now - seconds_before
  end

  def exist?(result_page)
    result_page['found']
  end

  def incorrect_letters?(attempt, grid)
    grid_hash = Hash.new(0)
    ('a'..'z').to_a.each { |letter| grid_hash[letter] = 0 }
    grid.split('').each { |letter| grid_hash[letter.downcase] += 1 }
    attempt.chars.each { |char| grid_hash[char.downcase] -= 1 }
    grid_hash.values.any?(&:negative?)
  end

  def calculate_result(attempt, grid, time_taken)
    result = {
      time: time_taken,
      score: 0,
      message: 0
    }

    url = open("https://wagon-dictionary.herokuapp.com/#{attempt}").read
    result_page = JSON.parse(url)
    if incorrect_letters?(attempt, grid)
      result[:score] = 0
      return result
    elsif exist?(result_page)
      result[:score] = result_page['length'] + (20.0 - time_taken)
    else
      result[:message] = 1
      return result
    end

    if result[:score] >= 20
      result[:message] = 6
    elsif result[:score] >= 10
      result[:message] = 5
    elsif result[:score] >= 5
      result[:message] = 4
    elsif result[:score].positive?
      result[:message] = 3
    elsif result[:score].negative?
      result[:message] = 2
    end
    result
  end
end
