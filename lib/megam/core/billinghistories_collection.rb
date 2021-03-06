##
## Copyright [2013-2015] [Megam Systems]
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
module Megam
  class BillinghistoriesCollection
    include Enumerable

    attr_reader :iterator
    def initialize
      @billinghistories = Array.new
      @billinghistories_by_name = Hash.new
      @insert_after_idx = nil
    end

    def all_billinghistories
      @billinghistories
    end

    def [](index)
      @billinghistories[index]
    end

    def []=(index, arg)
      is_megam_billinghistories(arg)
      @billinghistories[index] = arg
      @billinghistories_by_name[arg.accounts_id] = index
    end

    def <<(*args)
      args.flatten.each do |a|
        is_megam_billinghistories(a)
        @billinghistories << a
        @billinghistories_by_name[a.accounts_id] =@billinghistories.length - 1
      end
      self
    end

    # 'push' is an alias method to <<
    alias_method :push, :<<

    def insert(billinghistories)
      is_megam_billinghistories(billinghistories)
      if @insert_after_idx
        # in the middle of executing a run, so any predefs inserted now should
        # be placed after the most recent addition done by the currently executing
        # billinghistories
        @billinghistories.insert(@insert_after_idx + 1, billinghistories)
        # update name -> location mappings and register new billinghistories
        @billinghistories_by_name.each_key do |key|
        @billinghistories_by_name[key] += 1 if@billinghistories_by_name[key] > @insert_after_idx
        end
        @billinghistories_by_name[billinghistories.accounts_id] = @insert_after_idx + 1
        @insert_after_idx += 1
      else
      @billinghistories << billinghistories
      @billinghistories_by_name[billinghistories.accounts_id] =@billinghistories.length - 1
      end
    end

    def each
      @billinghistories.each do |billinghistories|
        yield billinghistories
      end
    end

    def each_index
      @billinghistories.each_index do |i|
        yield i
      end
    end

    def empty?
      @billinghistories.empty?
    end

    def lookup(billinghistories)
      lookup_by = nil
      if billinghistories.kind_of?(Megam::Billinghistories)
      lookup_by = billinghistories.accounts_id
      elsif billinghistories.kind_of?(String)
      lookup_by = billinghistories
      else
        raise ArgumentError, "Must pass a Megam::billinghistories or String to lookup"
      end
      res =@billinghistories_by_name[lookup_by]
      unless res
        raise ArgumentError, "Cannot find a billinghistories matching #{lookup_by} (did you define it first?)"
      end
      @billinghistories[res]
    end

    # Transform the ruby obj ->  to a Hash
    def to_hash
      index_hash = Hash.new
      self.each do |billinghistories|
        index_hash[billinghistories.accounts_id] = billinghistories.to_s
      end
      index_hash
    end

    # Serialize this object as a hash: called from JsonCompat.
    # Verify if this called from JsonCompat during testing.
    def to_json(*a)
      for_json.to_json(*a)
    end

    def self.json_create(o)
      collection = self.new()
      o["results"].each do |billinghistories_list|
        billinghistories_array = billinghistories_list.kind_of?(Array) ? billinghistories_list : [ billinghistories_list ]
        billinghistories_array.each do |billinghistories|
          collection.insert(billinghistories)
        end
      end
      collection
    end

    private

    def is_megam_billinghistories(arg)
      unless arg.kind_of?(Megam::Billinghistories)
        raise ArgumentError, "Members must be Megam::billinghistories's"
      end
      true
    end

    def to_s
      Megam::Stuff.styled_hash(to_hash)
    end

  end
end