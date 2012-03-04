classdef SHAHasher < handle
    % A simple, general purpose class for hashing matlab objects. Can
    % accept numeric / logical arrays, cell arrays, and structs / struct
    % arrays. Returns 160 byte hash in the form of a 20x1 int8 array.
    
    properties
        jmd % java.security.MessageDigest instance
    end
    
    % Public methods: constructor and hash
    methods (Access = public)
        % Constructor
        function hasher = SHAHasher
            try
                hasher.jmd = java.security.MessageDigest.getInstance('SHA');
            catch ex
                error('Java exception: %s', ex.message);
            end
        end
        
        % Public hash function
        function byteArr = hash(this, obj)
            if (isnumeric(obj) || islogical(obj))
                byteArr = hashArray(this, obj(:));
            elseif (ischar(obj))
                byteArr = hashArray(this, double(obj));
            elseif (isstruct(obj))
                if (isscalar(obj))
                    byteArr = hashStruct(this, obj);
                else
                    byteArr = hashStructArray(this, obj);
                end
            elseif (iscell(obj))
                byteArr = hashCell(this, obj);
            else
                error ('Can''t hash input with class %s.', class(obj));
            end
        end
    end
    
    % Protected methods: particular hash definitions. Note that many
    % recursively call back to `hash` above.
    methods (Access = protected)
        % We hash an array by directly digesting it.
        function byteArr = hashArray(this, arr)
            byteArr = this.jmd.digest(arr);
        end
        
        % We hash a struct by hashing each field, then hash the
        % concatenated array of those hashes.
        function byteArr = hashStruct(this, s)
            fields = fieldnames(s);
            n = length(fields);
            hashes = cell(n, 1);
            for i = 1:n
                hashes{i} = hash(this, s.(fields{i}));
            end
            byteArr = hashArray(this, vertcat(hashes{:}));
        end
        
        % Struct array: just hash each struct, then hash the hashes.
        function byteArr = hashStructArray(this, sa)
            sa = sa(:);
            n = length(sa);
            hashes = cell(n, 1);
            for i = 1:n
                hashes{i} = hashStruct(this, sa(i));
            end
            byteArr = hashArray(this, vertcat(hashes{:}));
        end
        
        % We hash a cell array by hash each element, then hashing the
        % concatenated array of those hashes.
        function byteArr = hashCell(this, c)
            c = c(:);
            n = length(c);
            hashes = cell(n, 1);
            for i = 1:n
                hashes{i} = hash(this, c{i});
            end
            byteArr = hashArray(this, vertcat(hashes{:}));            
        end
    end
    
end

