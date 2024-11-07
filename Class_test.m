classdef Class_test
    properties
        Property1
        Property2
    end
    
    methods
        function obj = Class_test(val1, val2)  % Constructor
            obj.Property1 = val1;
            obj.Property2 = val2;
        end
        
        function result = myMethod(obj, input)
            result = obj.Property1 + obj.Property2 + input;
        end
    end
end