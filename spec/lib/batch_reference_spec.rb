require "spec_helper"

module Neography
  module Composable
    describe BatchReference do
      describe "==" do
        specify do
          ref1 = BatchReference.new([:create, {"id" => 1}])
          ref2 = BatchReference.new([:create, {"id" => 1}])
          (ref1==ref2).should be_false
        end
        specify do
          command = [:create, {"id" => 1}]
          ref1 = BatchReference.new(command)
          ref2 = BatchReference.new(command)
          (ref1==ref2).should be_true
        end
        specify do
          command = [:create, {"id" => 1}]
          ref1 = BatchReference.new(command)
          ref1.after_submit do
            puts "Do this"
          end
          ref2 = BatchReference.new(command)
          ref2.after_submit do
            puts "Do something else"
          end
          (ref1==ref2).should be_false
        end
      end
    end
  end
end