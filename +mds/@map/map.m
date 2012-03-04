classdef map < handle
    % Provides a more sophisticated key/value map than Matlab's built in
    % containers.Map.
    % If you want to use your own class as the key, you need to provide a
    % hash function for it (probably a static method of the class). If not,
    % then this map can hash any built in Matlab type.
    
    properties (Constant, GetAccess = protected)
        DefaultNumBuckets = 100;
        ResizeLoadFactor = 2;
        ResizeGrowthFactor = 4;
    end
    
    properties (Access = protected)
        defaultSHAHasher % util.SHAHasher. Might be empty if not needed.
        hashFn % Function handle key -> 20x1 int8 array.
        buckets % Cell array: each is a bucket (array of structs)
        numElems % Total number of elements in the table
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
            switch(I(1).type)
                case '.'
                    % This sucks, basically. Overriding `subsref` overloads
                    % ., (), and {} jointly. So to get regular method call
                    % to work, we need to forward on to the builtin version
                    % which does the right thing.
                    v = builtin('subsref', this, I);
                case '()'
                    this.checkSubs(I);
                    v = this.get(I.subs{1});
                case '{}'
                    error('Indexing by {} not supported.');
            end
        end
        
        % Dispatches a set() from indexing.
        function this = subsasgn(this, I, B)
            this.checkSubs(I);
            this.set(I.subs{1}, B);
        end
        
        % Removes a key/val pair from the map. Returns true iff key was
        % actually present (and then removed).
        function wasPresent = remove(this, key)
            b = this.bucketForKey(key);
            [~, idx] = this.findInBucket(b, key);
            if (idx > 0)
                this.buckets{b}(idx) = [];
                this.numElems = this.numElems - 1;
                wasPresent = true;
            else
                wasPresent = false;
            end
        end
        
        % Applies func to the val for key. If key is not present, then
        % default behavior is to no-op an return []. If optionalDefaultVal
        % is provided, then instead a new entry mapping key to
        % func(optionalDefaultVal) is created. A natural use is, say, a map
        % of counts of keys. Then func can by @(x)(x+1) and the optional
        % default val is 0.
        function newVal = apply(this, key, func, optionalDefaultVal)
            b = this.bucketForKey(key);
            [~, idx] = this.findInBucket(b, key);
            if (idx > 0)
                this.buckets{b}(idx).val = func(this.buckets{b}(idx).val);
                newVal = this.buckets{b}(idx).val;
            else
                if (exist('optionalDefaultVal', 'var'))
                    newVal = func(optionalDefaultVal);
                    this.insertNewRecord(b, key, newVal);
                else
                    newVal = [];
                end
            end
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
            if (this.numElems / length(this.buckets) > this.ResizeLoadFactor)
                this.Rehash();
            end
            
            b = this.bucketForKey(key);
            [~, idx] = this.findInBucket(b, key);
            if (idx > 0)
                this.buckets{b}(idx).val = val;
            else
                this.insertNewRecord(b, key, val);
            end
        end
        
        function insertNewRecord(this, b, key, val)
            rec = struct('key', key, 'val', val);
            this.buckets{b} = [this.buckets{b} rec];
            this.numElems = this.numElems + 1;
        end
        
        function Rehash(this)
            n = length(this.buckets);
            oldBuckets = this.buckets;
            this.buckets = cell(this.ResizeGrowthFactor * n, 1);
            
            for i = 1:n
                bucket = oldBuckets{b};
                for j = 1:length(bucket)
                    b = bucketForKey(bucket(j).key);
                    this.buckets{b} = [this.buckets{b} bucket(j)];
                end
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
