#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

class ChartDatasets

  def initialize(from_date, to_date)
    @data = Hash.new
    @counts = Hash.new
    @from_date = from_date
    @to_date = to_date
  end

  def initialize_datasets()
    @counts.each.map{ |label,count|
      @data[label] = [[@from_date.to_datetime.beginning_of_day.to_i * 1000,
                           count]]
    }
  end

  def finalize_datasets()
    @counts.each.map{ |label,count|
      @data[label] << [@to_date.to_datetime.end_of_day.to_i * 1000, count]
    }
  end

  def increment_count(label, increment)
    if !@counts.has_key?(label)
      @counts[label] = 0
    end

    @counts[label] = @counts[label] + increment
  end

  def add_dataset_point(label, timestamp, increment)
    if !@data.has_key?(label)
      @data[label] = [[timestamp - 1, 0]]
    else
      @data[label] << [timestamp - 1, @counts[label]]
    end

    increment_count(label,increment)
    @data[label] << [timestamp, @counts[label]]
  end

  def to_a
    return @data.to_a.sort{ |a,b|
      if a[0] == "All"
        -1
      elsif b[0] == "All"
        1
      else
        a[0] <=> b[0]
      end
    }
  end
end
