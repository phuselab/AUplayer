
function data = csvparser(filename)

   % Get the header
   fid = fopen(filename, 'r');
   if fid < 0
      error(['Can''t open file "' filename '" for reading.']);
   end
   header = fgetl(fid); % Read header line
   header = strrep(header, ' ', '');
   header = strrep(header, '_r', '');
   header = strrep(header, 'AU0', 'AU');
   header = lower(header);
   fclose(fid);

   % Convert header string to a cell array with field names.
   fields = eval(['{''', strrep(header, ',', ''','''), '''}']);

   % Get the data
   data = csvread(filename, 1, 0);

   data = data(:, 1:21);
   fields = fields(:, 1:21);

   % Convert data into a cell array of values.
   values = num2cell(data, 1);

   % Build structure
   list = { fields{:} ; values{:} };
   data = struct(list{:});
   
   save([filename(1:end-4) '_openface.mat'], 'data');