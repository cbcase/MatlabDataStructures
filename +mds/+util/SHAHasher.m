classdef SHAHasher < handle
    % A simple, general purpose class for hashing matlab objects. Can
    % accept numeric / logical arrays, cell arrays, and structs / struct
    % arrays. Returns 160 byte hash in the form of a 20x1 int8 array.
    
    properties
        jmd % java.security.MessageDigest instance
        wordtype % Either 'uint32' or 'uint64'.
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
            
            % Check the output of `computer`
            c = computer;
            if (strcmp(c(end-1:end), '64'))
                hasher.wordtype = 'uint64';
            else
                hasher.wordtype = 'uint32';
            end
        end
        
        % Hash to raw 160 byte array.
        function byteArr = hashToBytes(this, obj)
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
        
        % Hash to machine word size integer.
        function val = hash(this, obj)
            val = this.intFromBytes(this.hashToBytes(obj));
        end
    end
    
    methods (Access = public, Static = true)
    end
    
    % Protected methods: particular hash definitions. Note that many
    % recursively call back to `hashToBytes` above.
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
                hashes{i} = hashToBytes(this, s.(fields{i}));
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
                hashes{i} = hashToBytes(this, c{i});
            end
            byteArr = hashArray(this, vertcat(hashes{:}));            
        end
        
        % Takes the first 32 / 64 bits of byte array and converts to uint32
        % or uint64, depending on your machine's word size.
        function val = intFromBytes(this, bytes)
            intRep = typecast(bytes(1:8), this.wordtype);
            val = intRep(1);
        end
    end
    
end

