function AUplayer(dataset, subjectid, sessionid)

addpath('AUVs');


[dataFile, videoFile] = prepareFiles(dataset, subjectid, sessionid);


global h1 h3 hp hl hc vid fields activefields candide3 triangles pf auvs au2auv fs aubuttons;

%matrice con vertici candide3
candide3 = load('candide3.dat');

%matrice con triangoli candide3
triangles = load('triangles.dat');
triangles = triangles + 1;

% auv names
auvNames = {'auv0', 'auv2', 'auv3', 'auv4', 'auv5', 'auv6', 'auv7', 'auv8', 'auv9', 'auv10', 'auv11', 'auv14'};

% au corresponding to auvs, in terms of fields index
au2auv = {8, 17, 3, 10, 2, 24, 6, 7, [19, 20], 4, [22, 23], [11, 13]};

for i = 1:length(auvNames)
    auvs{i} = load(['AUVs/' auvNames{i} '.dat']);
end

% all possible AU
fields = {'au1',  'au2',  'au4',  'au5',  'au6',  'au7',  'au9', ...
    'au10', 'au11', 'au12', 'au13', 'au14', 'au15', 'au16', ...
    'au17', 'au18', 'au20', 'au22', 'au23', 'au24', 'au25' ...
    'au26', 'au27', 'au45'};

desc = {'Inner Brow Raiser', 'Outer Brow Raiser', 'Brow Lowerer',...
    'Upper Lid Raiser','Cheek Raiser', 'Lid Tightener', 'Nose Wrinkler',...
    'Upper Lip Raiser', 'Nasolabial Deepener','Lip Corner Puller', 'Cheek Puffer',...
    'Dimpler', 'Lip Corner Depressor', 'Lower Lip Depressor', 'Chin Raiser',...
    'Lip Puckerer', 'Lip stretcher', 'Lip Funneler', 'Lip Tightener','Lip Pressor', ...
    'Lips part', 'Jaw Drop', 'Mouth Stretch', 'Blink' };


activefields = zeros(1,length(fields));


disp('Processing AU features...');

close;

figure('KeyReleaseFcn',@Key_Up, 'units','normalized','outerposition',[0 0 1 1]);

% carica i dati
pf = load(dataFile);
datamin = inf;
datamax = -inf;
dataLen = 0;
for f = 1:length(fields)
    if isfield(pf.data, fields{f})
        % save reference to available fields
        tmpdata{f} = pf.data.(fields{f})';
        dataLen = length(tmpdata{f});
        if min(tmpdata{f}) < datamin
            datamin = min(tmpdata{f});
        end
        if max(tmpdata{f}) > datamax
            datamax = max(tmpdata{f});
        end
    end
end


vid = VideoReader(videoFile);

fs = dataLen/vid.Duration;

x = linspace(0, vid.Duration, dataLen);

curFrame = 0;

% plotta il video nella parte superiore
h1 = subplot(2,2,1);
h1.UserData = 0; % is playing
vid.CurrentTime = fs*curFrame;
imshow(readFrame(vid));

% plotta il grafico nella parte inferiore
h2 = subplot(2,2,[3 4]);
hp = {};
for i = 1:length(fields)
    if ~isempty(tmpdata{i})
        hp{i} = plot(x, tmpdata{i}, 'Visible', 'off');
        hold on;
    end
end
xlim([0 vid.Duration]);
hl = line([0 0],[datamin datamax], 'LineWidth', 2, 'Color', 'red');

% CANDIDE
h3 = subplot(2,2,2);
c = zeros(1,length(triangles))';
%change eyes color
c(157:160) = -1;
% plotta candide3
hc = trisurf(triangles,candide3(:,1),candide3(:,2),candide3(:,3),c);
colormap gray;
%shading interp;
material dull;
light('Position',[-1 1 1], 'Style', 'local');
view(0,90)
axis equal
axis off

aubuttons = zeros(1, length(fields));

for i = 1:length(fields)
    if ~isempty(tmpdata{i})
        enable = 'on';
    else
        enable = 'off';
    end
    
    [x,~] = imread(['img/' fields{i} '.png']);
    I2 = imresize(x, [42 113]);
    
    aubuttons(i) = uicontrol('Style', 'togglebutton',...
        'String', fields{i},...
        'TooltipString', desc{i}, ...
        'position',[5+80*(mod(i,2)) 50*(ceil(i/2)) 80 50],...
        'CData', I2, ...
        'Callback', @toggleAU, ...
        'Enable', enable);
end

uicontrol('Style', 'pushbutton',...
    'String', 'Enable all AUV',...
    'TooltipString', 'Enable all AUV', ...
    'position',[5 0 160 50],...
    'Callback', @enableAllAUV, ...
    'Enable', enable);

set(h2, 'ButtonDownFcn', @moveVideo)

function toggleAU(source, ~)
global activefields fields
if source.Value == 1
    source.BackgroundColor = 'red';
    for i = 1:length(fields)
        if strcmp(fields{i},source.String)
            activefields(i) = 1;
        end
    end
else
    source.BackgroundColor = [.94 .94 .94];
    for i = 1:length(fields)
        if strcmp(fields{i},source.String)
            activefields(i) = 0;
        end
    end
end
redraw();

function redraw
global activefields hp;
for f = 1:length(activefields)
    if (activefields(f) == 1)
        set(hp{f}, 'visible', 'on');
    else
        set(hp{f}, 'visible', 'off');
    end
end

function enableAllAUV(source, ~)
global au2auv fields activefields aubuttons;

for auv = 1:length(au2auv)
    au = au2auv{auv};
    for a = 1:length(au)
        for i = 1:length(fields)
            str = get(aubuttons(i), 'String');
            val = get(aubuttons(i), 'Value');
            en = get(aubuttons(i), 'Enable');
            if strcmp(en, 'on') && val == 0 && strcmp(fields{au(a)}, str)
                set(aubuttons(i), 'Value', 1);
                set(aubuttons(i), 'BackgroundColor', 'red');
                activefields(i) = 1;
            end
        end
    end
end
redraw();

function togglePlay()
global h1 hl vid
if (h1.UserData == 0)
    h1.UserData = 1;
    while hasFrame(vid) && h1.UserData == 1
        imh = imhandles(h1);
        set(imh, 'CData', readFrame(vid));
        set(hl, 'XData', [vid.CurrentTime vid.CurrentTime]);
        drawnow;
        transformCandide();
    end
    h1.UserData = 0;
else
    h1.UserData = 0;
end

function Key_Up(~,evnt)
if(evnt.Character == ' ')
    togglePlay();
end

function moveVideo(~, ~)
global h1 hl vid
C = get (gca, 'CurrentPoint');
vid.CurrentTime = C(1,1);
imh = imhandles(h1);
set(imh, 'CData', readFrame(vid));
set(hl, 'XData', [C(1,1) C(1,1)]);
transformCandide();

function transformCandide()
global hc h3 fields candide3 pf activefields auvs au2auv vid fs;

subplot(2,2,2)
candidet = candide3;
curX = round(vid.CurrentTime * fs);

score = pf.data.confidence(curX);

% for each candide vertex
for v = 1:length(candide3)
    newX = 0;
    newY = 0;
    newZ = 0;
    % for each auv
    for auv = 1:length(auvs)
        value = 0;
        contribs = 0;
       
        % check if current vertex is affected by current auv
        line = find(auvs{auv}(:,1)+1 == v);
            
        if (line > 0)
            au = au2auv{auv};
            % for each au corresponding to current auv
            for a = 1:length(au)
                % if enabled, get activation value
                if activefields(au(a))
                    value = value + tanh(pf.data.(fields{au(a)})(curX));
                    contribs = contribs + 1;
                end
            end
            
            if (contribs > 0)
                value = value / contribs;
                newX = newX + (auvs{auv}(line,2) * value);
                newY = newY + (auvs{auv}(line,3) * value);
                newZ = newZ + (auvs{auv}(line,4) * value);
            end
        end
    end
    
    candidet(v,1) = candidet(v,1) + newX;
    candidet(v,2) = candidet(v,2) + newY;
    candidet(v,3) = candidet(v,3) + newZ;
end
title(h3, score);
hc.Vertices = candidet;

function [dataFile, videoFile] = prepareFiles(dataset, subjectid, sessionid)
switch dataset
    case 'phuse'
        subjectid = num2str(subjectid);
        sessionid = num2str(sessionid);        
        % folder with video        
        video_folder = ['/media/vcuculo/Data/Datasets/Phuse/data/' subjectid];
        % file containing AU
        dataFile = ['data/' subjectid '_' sessionid '_au_openface.mat'];
        % file containing video
        videoFile = [video_folder '/' subjectid '_' sessionid '.avi'];
        %videoFile = [video_folder subjectid '.mp4'];
    
    case 'recola'
        subjectid = subjectid;        
        % folder with original AU        
        data_folder = '/media/vcuculo/Data/Datasets/RECOLA/RECOLA-Video-features/';        
        % folder with video
        video_folder = '/media/vcuculo/Data/Datasets/RECOLA/RECOLA-Video-recordings/';
        % file containing AU
        dataFile = ['data/' subjectid '_au_openface.mat'];
        % file containing video
        videoFile = [video_folder '/' subjectid '.avi'];
        %videoFile = [video_folder subjectid '.mp4'];    
    
        % se non esiste il .mat lo crea dal .arff
        if ~exist(dataFile, 'file')
            dataFile = ['data/' subjectid '_au_original.mat'];
            fprintf('Data file does not exists, creating...');
            data = arffparser('read', strcat(data_folder, subjectid, '.arff'));
            save(dataFile, 'data');
            fprintf('DONE!\n');
        end  
end