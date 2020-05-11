function crave_gen_stopsignal_updated(ssids)
% Script created by Caitlin R. Bowman (Zeithamova Lab, 11/25/2018)
% Generates vector file for crave control
% Inputs are:
% ssids: a vector of all subject IDs (e.g. [1:3 5 9:14] if you need to skip
% subjects, 1:100 if you don't); no need for leading zeros.


%% These are directories you can change.

resultdir = '/Volumes/Milkshake/CraveControl/vectors/vectors/logs/stop'; % Change this to the directory where the subjects' data folders are located
savedir = '/Volumes/Milkshake/CraveControl/vectors/vectors/stop'; % Change this to the directory where you would like the vector files saved

%resultdir = '/Users/Cait/Desktop/ORI/VectorFiles/20200121'; % Change this to the directory where the subjects' data folders are located
%savedir = [resultdir '/out']; % Change this to the directory where you would like the vector files saved


if ~exist(savedir,'dir')
    mkdir(savedir);
end
% The first points to where the behavioral files are located.
% It assumes that within the directory indicated for resultdir there will
% be a file with an individual subject's data in the format
% CC###_stopsignal_fMRI_clean.csv
% (e.g.,CC001, CC010, CC100).

% The second is where to save out the vector files.

for s = 1:length(ssids)
    [ons,durs,corr,picname] = importfile([resultdir sprintf('/CC%03d_stopsignal_fMRI_clean.csv',ssids(s))],2,inf);
    
    
    for i = 1:size(picname,1)
        this = char(picname{i,1});
        isgo(i,1) = strcmp('h',this(1)) | strcmp('b',this(1)) | strcmp('3',this(2));
    end
    
    iscorr = (corr > 0 & isgo) | (corr == 0 & ~isgo);
    
    ons = ons/1000;
    durs = durs/1000;
    
    %% Output with all trials separated only by go vs. nogo
    names = {'go','nogo'};
    onsets{1,1} = ons(isgo);
    onsets{1,2} = ons(~isgo);
    
    durations{1,1} = durs(isgo);
    durations{1,2} = durs(~isgo);
    
    save([savedir sprintf('/CC%03d_alltrials.mat',ssids(s))],'names','onsets','durations');
    
    %% Output with incorrect trials binned separately from correct go vs. nogo trials
    names = {'go','nogo','incorrect'};
    onsets{1,1} = ons(isgo & iscorr);
    onsets{1,2} = ons(~isgo & iscorr);
    onsets{1,3} = ons(~iscorr);
    
    durations{1,1} = durs(isgo & iscorr);
    durations{1,2} = durs(~isgo & iscorr);
    durations{1,3} = durs(~iscorr);
    
    save([savedir sprintf('/CC%03d_corrtrials.mat',ssids(s))],'names','onsets','durations');
    
    %% Output with onsets blocked into 12 trial sets
    nts = 12; % number of trials per chunk: can change and everything below updates
    numit = ceil(size(ons,1)/nts);
    names = {};
    onsets = {};
    durations = {};
    for b = 1:numit
        starttrial = ((b-1)*nts) + 1;
        endtrial = b*nts;
        columnstart = ((b-1)*2)+1;
        
        if endtrial > size(ons,1) % if total trials is not divisible by nts, last chunk will have fewer trials
            endtrial = size(ons,1);
        end
        
        theseons = ons(starttrial:endtrial);
        thesedurs = durs(starttrial:endtrial);
        thesegoes = isgo(starttrial:endtrial);
        
        names = [names sprintf('go%d',b) sprintf('nogo%d',b)];
        onsets{1,columnstart} = theseons(thesegoes==1);
        onsets{1,columnstart+1} = theseons(thesegoes==0);
        durations{1,columnstart} = thesedurs(thesegoes==1);
        durations{1,columnstart+1} = thesedurs(thesegoes==0);
    end
    
    save([savedir sprintf('/CC%03d_%dblks_%dtrials.mat',ssids(s),numit,nts)],'names','onsets','durations');
    
    %% Output with onsets blocked into 10 trial sets
    nts = 10; % number of trials per chunk: can change and everything below updates
    numit = ceil(size(ons,1)/nts);
    names = {};
    onsets = {};
    durations = {};
    for b = 1:numit
        starttrial = ((b-1)*nts) + 1;
        endtrial = b*nts;
        columnstart = ((b-1)*2)+1;
        
        if endtrial > size(ons,1) % if total trials is not divisible by nts, last chunk will have fewer trials
            endtrial = size(ons,1);
        end
        
        theseons = ons(starttrial:endtrial);
        thesedurs = durs(starttrial:endtrial);
        thesegoes = isgo(starttrial:endtrial);
        
        names = [names sprintf('go%d',b) sprintf('nogo%d',b)];
        onsets{1,columnstart} = theseons(thesegoes==1);
        onsets{1,columnstart+1} = theseons(thesegoes==0);
        durations{1,columnstart} = thesedurs(thesegoes==1);
        durations{1,columnstart+1} = thesedurs(thesegoes==0);
    end
    
    save([savedir sprintf('/CC%03d_%dblks_%dtrials.mat',ssids(s),numit,nts)],'names','onsets','durations');
    
    %% Output with blocks of 10 go, 10 nogo trials
    nts = 10; % number of trials per chunk: can change and everything below updates
    numit = ceil(sum(isgo)/nts);
    names = {};
    onsets = {};
    durations = {};
    goons = ons(isgo);
    ngons = ons(~isgo);
    godurs = durs(isgo);
    ngdurs = durs(~isgo);
    for b = 1:numit
        starttrial = ((b-1)*nts) + 1;
        endtrialgo = b*nts;
        endtrialng = b*nts;
        columnstart = ((b-1)*2)+1;
        
        if endtrialgo > sum(isgo) || endtrialng > sum(~isgo) % if total trials is not divisible by nts, last chunk will have fewer trials
            endtrialgo = sum(isgo);
            endtrialng = sum(~isgo);
        end
        
       
        
        names = [names sprintf('go%d',b) sprintf('nogo%d',b)];
        onsets{1,columnstart} = goons(starttrial:endtrialgo);
        onsets{1,columnstart+1} = ngons(starttrial:endtrialng);
        durations{1,columnstart} = godurs(starttrial:endtrialgo);
        durations{1,columnstart+1} = ngdurs(starttrial:endtrialng);
    end
    
    save([savedir sprintf('/CC%03d_go_nogo_%dblks_%dtrials.mat',ssids(s),numit,nts)],'names','onsets','durations');
 
        %% Output with blocks of 20 go, 20 nogo trials
    nts = 20; % number of trials per chunk: can change and everything below updates
    numit = ceil(sum(isgo)/nts);
    names = {};
    onsets = {};
    durations = {};
    goons = ons(isgo);
    ngons = ons(~isgo);
    godurs = durs(isgo);
    ngdurs = durs(~isgo);
    for b = 1:numit
        starttrial = ((b-1)*nts) + 1;
        endtrialgo = b*nts;
        endtrialng = b*nts;
        columnstart = ((b-1)*2)+1;
        
        if endtrialgo > sum(isgo) || endtrialng > sum(~isgo) % if total trials is not divisible by nts, last chunk will have fewer trials
            endtrialgo = sum(isgo);
            endtrialng = sum(~isgo);
        end
        
       
        
        names = [names sprintf('go%d',b) sprintf('nogo%d',b)];
        onsets{1,columnstart} = goons(starttrial:endtrialgo);
        onsets{1,columnstart+1} = ngons(starttrial:endtrialng);
        durations{1,columnstart} = godurs(starttrial:endtrialgo);
        durations{1,columnstart+1} = ngdurs(starttrial:endtrialng);
    end
    
    save([savedir sprintf('/CC%03d_go_nogo_%dblks_%dtrials.mat',ssids(s),numit,nts)],'names','onsets','durations');

    
    %% Output with first and last 10 events
    onsets(:,3) = [];
    durations(:,3) = [];
    names = {'First10Events', 'Last10Events'};
    onsets{1,1} = ons(1:10);
    onsets{1,2} = ons(end-9:end);
    
    durations{1,1} = durs(1:10);
    durations{1,2} = durs(end-9:end);
    
    save([savedir sprintf('/CC%03d_blocks.mat',ssids(s))],'names','onsets','durations');
    
    %% Output with a moving window of 5 events
    window = 5;
    go_onsets = ons(isgo);
    go_durations = durs(isgo);
    go_len = length(go_onsets) - window;
    for i=1:go_len
        names{1,i} = sprintf('go%d', i);
        onsets{1,i} = go_onsets(i:i+window);
        durations{1,i} = go_durations(i:i+window);
    end
    no_go_onsets = ons(~isgo);
    no_go_durations = durs(~isgo);
    no_go_len = length(no_go_onsets) - window;
    for i=1:no_go_len
        names{1,i+length(go_onsets)} = sprintf('nogo%d', i);
        onsets{1,i+length(go_onsets)} = no_go_onsets(i:i+window);
        durations{1,i+length(go_onsets)} = no_go_durations(i:i+window);
    end
    
    save([savedir sprintf('/CC%03d_moving_average.mat',ssids(s))],'names','onsets','durations');
    clear isgo names onsets durations;
end
