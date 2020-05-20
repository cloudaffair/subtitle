
require "json"

SENTENCE_CONTINUATION_DIFF = 0.1
SINGLE_SRT_SECONDS_LENGTH = 3
CONTINUATION_SENTENCE_OVERLOAD = 3


class SrtHelper

	def parse_file(input_file, output_file)
		cf =File.read(input_file)
		data = JSON.parse(cf)
		sentence_list = []
		str = ""

		prev_end_time = nil
		sentence_start_time = nil
		sentence_end_time = nil
		data["results"]["items"].each do |item|
			content = item["alternatives"][0]["content"]
			#puts content

			if item["type"].eql?("pronunciation")
				start_time = item["start_time"]
				end_time = item["end_time"]
				if prev_end_time.nil?
					prev_end_time = end_time
					sentence_start_time = start_time
					sentence_end_time = end_time
					str = content
				else
					if prev_end_time == start_time
						str = "#{str} #{content}"
						sentence_end_time = end_time
						prev_end_time = end_time
					else
						# End of Sentence
						# So this word should come in the next sentence
						sentence_object = {"sentence" => str , "start_time" => sentence_start_time , "end_time" => sentence_end_time, "punctuation" => false}
						sentence_list << sentence_object
						str = content
						sentence_start_time = start_time
						sentence_end_time = end_time
						prev_end_time = end_time
					end
				end
			else
				str = "#{str}#{content}"
				sentence_object = {"sentence" => str , "start_time" => sentence_start_time , "end_time" => sentence_end_time, "punctuation" => true}
				sentence_list << sentence_object
				str = ""
				prev_end_time = nil
			end
		end

		# Merge all the sentence based on 10 milli second gap and Punctuation
	
		new_sentence_list = []
		sentence = ""
		sentence_start_time = nil
		sentence_end_time = nil
		sub_list = []
		sentence_list.each do |sent|
			content = sent["sentence"]
			if sentence_start_time.nil?
				sentence = content
				sentence_start_time = sent["start_time"]
				sentence_end_time = sent["end_time"]
				sub_list << sent
			else
				sentence_start_time_f = sentence_start_time.to_f
				sentence_end_time_f = sentence_end_time.to_f
				start_time_f = sent["start_time"].to_f
				end_time_f = sent["end_time"].to_f
				cont_diff = start_time_f - sentence_end_time_f
				total_sec_len = end_time_f - sentence_start_time_f
				
				if cont_diff > SENTENCE_CONTINUATION_DIFF || (total_sec_len > SINGLE_SRT_SECONDS_LENGTH && word_count(content) < CONTINUATION_SENTENCE_OVERLOAD)
					# Need to end the sentence
					sentence_object = {"sentence" => sentence , "start_time" => sentence_start_time , "end_time" => sentence_end_time, "sub_list" => sub_list}
					new_sentence_list << sentence_object
					sentence = content
					sentence_start_time = sent["start_time"]
					sentence_end_time = sent["end_time"]
					sub_list = []
				else
					sentence = "#{sentence} #{content}"
					sentence_end_time = sent["end_time"]
					sub_list << sent
				end

			end
		end

		srt_generator(new_sentence_list, output_file)
	end


	def word_count(word)
		str = word.strip
		str_arr = str.split(" ")
		return str_arr.size
	end

	def convert_time_srt_fmt(val)
		val = val.to_f
		milliseconds = ((val * 1000) % 1000).to_i
		val = val.to_i
		seconds = val % 60
		minutes = val / 60
		minutes = minutes % 60
		hours = minutes / 60
		srt_fmt = "#{convert_to_two_digit(hours)}:#{convert_to_two_digit(minutes)}:#{convert_to_two_digit(seconds)},#{milliseconds}"
	end

	def convert_to_two_digit(val)
		if val > 9
			val = "#{val}"
		else
			val = "0#{val}"
		end
		val
	end

	def srt_generator(list, output_file)
		file = File.open(output_file, "w")
		count = 0
		list.each do |sent|
			count +=1
			srt_fmt_strt_time = convert_time_srt_fmt(sent["start_time"])
			srt_fmt_end_time = convert_time_srt_fmt(sent["end_time"])
			file.puts(count)
			file.puts("#{srt_fmt_strt_time} --> #{srt_fmt_end_time}")
			file.puts(sent["sentence"])
			file.puts
		end
	end

end

