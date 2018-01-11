% Find directory dynamically
dirparts = strsplit(pwd, '/');
data_dir = [];
for pi = 1:length(dirparts)-1
    data_dir = [data_dir, dirparts{pi}, filesep];
end
disp(['Processing from directory: ',data_dir]);
trialnums = 1:4;

for trialnum = trialnums
    extra_dir = '/full_cam/';
    source_dir = [data_dir,'Trial',num2str(trialnum,'%02d'),extra_dir];
    load([source_dir,'img_timestamps.mat'],'img_files','T');
            % Sort images by timestamps
            [T,Tinds] = sort(T);
            img_files = img_files(Tinds);
    save([source_dir,'img_timestamps.mat'],'img_files','T');
end