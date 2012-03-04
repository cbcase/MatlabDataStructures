classdef map < handle
    % Provides a more sophisticated key/value map than Matlab's built in
    % containers.Map.
    % If you want to use your own class as the key, you need to provide a
    % hash function for it (probably a static method of the class). If not,
    % then this map can hash any built in Matlab type.
    
    properties (Constant)
        DefaultNumBuckets = 100;
    end
    
    properties
        defaultSHAHasher % util.SHAHasher. Might be empty if not needed.
        hashFn % Function handle key -> 20x1 int8 array.
        buckets
    end
    
    methods
        function m = map(hashFn)
            if (nargin == 0)
                m.defaultSHAHasher = mds.util.SHAHasher;
                m.hashFn = @(obj) m.defaultSHAHasher.hash(obj);
            else
                m.hashFn = hashFn;
            end
            m.buckets = cell(m.DefaultNumBuckets, 1);
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
            b = this.bucketForKey(key);
            v = this.findInBucket(b, key);
        end
        
        function set(this, key, val)
            b = this.bucketForKey(key);
            [~, idx] = this.findInBucket(b, key);
            if (idx > 0)
                this.buckets{b}(idx).val = val;
            else
                % Insert new record
                rec = struct('key', key, 'val', val);
                this.buckets{b} = [this.buckets{b} rec];
            end
            
        end
        
        function [val, idx] = findInBucket(this, b, key)
            bucket = this.buckets{b};
            for i = 1:length(bucket)
                if (isequal(key, bucket.key))
                    val = bucket.val;
                    idx = i;
                    return;
                end
            end
            val = [];
            idx = 0;
        end       
        
        function b = bucketForKey(this, key)
            k = length(this.buckets);
            b = mod(this.hashFn(key), k);
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
