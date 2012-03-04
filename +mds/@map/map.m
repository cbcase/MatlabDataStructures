classdef map < handle
    % Provides a more sophisticated key/value map than Matlab's built in
    % containers.Map.
    % If you want to use your own class as the key, you need to provide a
    % hash function for it (probably a static method of the class). If not,
    % then this map can hash any built in Matlab type.
    
    properties
        defaultSHAHasher % util.SHAHasher. Might be empty if not needed.
        hashFn % Function handle key -> 20x1 int8 array.
    end
    
    methods
        % TODO: it should be possible to define a UniformValue map so that
        % each bucket is an array rather than a linked list
        function m = map(hashFn)
            if (nargin == 0)
                m.defaultSHAHasher = mds.util.SHAHasher;
                m.hashFn = @(obj) m.defaultSHAHasher.hash(obj);
            else
                m.hashFn = hashFn;
            end
        end
        
        % Dispatches a get() from indexing.
        function v = subsref(this, I)
            this.checkSubs(I);
            v = this.get(I.subs{1});
        end
        
        % Dispatches a set() from indexing.
        function this = subsasgn(this, I, B)
            this.checkSubs(I);
            this.set(I.subs{1}, B);
        end
        
    end
    
    methods (Access = protected)
        % Get and set are protected now so that only access is through
        % subsref. Might make public, but only if it can provide
        % meaningfully different semantics.
        function v = get(this, key)
            fprintf('Getting key:\n');
            disp(key);
            % TODO: implement
            v=0;
        end
        
        function set(this, key, val)
            fprintf('Setting key:\n');
            disp(key);
            fprintf('To val:\n');
            disp(val);
            % TODO: implement
        end
    end
    
    methods (Access = protected, Static = true)        
        % Check that an indexing expression is valid: only one key, using
        % parens.
        function checkSubs(I)
            if (~strcmp(I.type, '()'))
                error('Invalid indexing type %s for mds.map', I.type);
            end
            if (length(I.subs) ~= 1)
                error('Index for mds.map must be a single object, was given %d', length(I.subs));
            end
        end
    end
    
end
