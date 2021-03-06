% main_Yale : Main script for frequency of convergence experiments on Yale database
% The methods tested are listed in the variable alg_list
% 'affine_ic'             		          corresponds to ref. [5] of the paper
% 'affine_ECC_ic'         		          corresponds to ref. [14] of the paper 
% 'affine_ic_irls'        		          corresponds to ref. [6] of the paper 
% 'affine_GaborFourier_ic'                corresponds to ref. [13] of the paper
% 'affine_GradientImages_ic'              corresponds to the method "GradientImages" also described in the paper (Please see section 5.2 of the paper)
% 'affine_GradientCorr_ic'                corresponds to the proposed method "GradientCorr"
% 
% Set verbose = 1 to show the fitting procedure. If verbose = 0, the fitting is not shown. 
% 
% For each script, the average frequency of convergence results are stored in the "results" variable. 
% This is a 4-D matrix: results(subj, i, s, l)
% subj denotes the subject under examination (10 subjects in total for Yale)
% i    denotes the image pair under examination (10 image pairs for each subject for Yale)
% s    denotes the initial point RMS (parameter sigma in the paper, 100 tests are carried out for each s)
% l    denotes the method examined 
%   l=1 corresponds to 'affine_ic'  
%   l=2 corresponds to 'affine_ECC_ic'    
%   l=3 corresponds to 'affine_ic_irls' 
%   l=4 corresponds to 'affine_GaborFourier_ic' 
%   l=5 corresponds to 'affine_GradientImages_ic'
%   l=6 corresponds to the proposed 'affine_GradientCorr_ic'  
% Example: results(3, 1, 10, 6) gives the average frequency of convergence (over 100 tests) for initial point RMS = 10
% of the proposed GradientCorr method tested on the 1st image pair of the 3rd subject.

% Based on the implementation of Iain Matthews, Simon Baker, Carnegie Mellon University, Pittsburgh
% http://www.ri.cmu.edu/research_project_detail.html?project_id=515&menu_id=261

% Described in G. Tzimiropoulos, S. Zafeiriou and M. Pantic, "Robust and Efficient Parametric Face Alignment", ICCV 2011.
% Intelligent Behaviour Understanding Group (IBUG), Department of Computing, Imperial College London
% Version: 1.0, 03/01/2012

clear; close all; clc; warning off

addpath methods
addpath tools
addpath data

load myYaleCropped.mat

% List of algorithms to run
% Get all non-3d algorithms
alg_list = get_all_files('methods', 'affine(_[\w]+)?_ic(?!_3d)([_A-Za-z]+)?\.(p|m)');
alg_list = cellfun(@(x) x(1:length(x)-2), alg_list, 'UniformOutput', false);
% alg_list = {'affine_GradientCorr_ic' 'affine_GradientCorr_Euclidean_ic'};

% Test parameters
verbose = 1;					% Show fitting?
n_iters = 30;					% Number of gradient descent iterations
n_freq_tests = 100;			    % Number of frequency of convergence tests
max_spatial_error = 3.0;		% Max location error for deciding convergence
all_spc_sig = 1:1:10;        	% All spatial sigmas

% pt_offset - precomputed random point offsets, provided by Iain Matthews, Simon Baker, Carnegie Mellon University, Pittsburgh
load('affine_pt_offset');

num_of_imgs_per_subj = size(example_imgs, 3)/num_of_subjs;
count = 0;
results = zeros(num_of_subjs, num_of_imgs_per_subj, length(all_spc_sig), length(alg_list));
for subj = 1:1:num_of_subjs
    subj
    example_imgs_per_subj = example_imgs(:, :, num_of_imgs_per_subj*(subj-1)+1:num_of_imgs_per_subj*subj);
    tmplt = tmplts(:, :, subj);
    
    for i = 1:1:num_of_imgs_per_subj
        tdata.img1 = example_imgs_per_subj(:, :, i);
        tdata.img2 = tmplt;
        tdata.tmplt = coords;
        
        % Matrix S for Gabor-Fourier method, thanx to Peter Kovesi's Gabor Filters, http://www.csse.uwa.edu.au/~pk/
        temp = ones(tdata.tmplt(4)-tdata.tmplt(2)+1, tdata.tmplt(3)-tdata.tmplt(1)+1);
        num_of_scales = 32; num_of_or = 32;
        [EO, BP, S] = gaborconvolve(temp, num_of_scales, num_of_or , 3, 2, 0.65);
        save S.mat S;
              
        % Run tests
        for s=1:length(all_spc_sig)
            spatial_sigma = all_spc_sig(s);
            
            if verbose == 1
            disp(['DIVG - Spatial: ', num2str(spatial_sigma)]);
            end
            
            res = my_test_affine(tdata, pt_offset, alg_list, n_iters, n_freq_tests, spatial_sigma, max_spatial_error, verbose);
            for l = 1:length(alg_list)
            n_converge = getfield(res, {1}, alg_list{l}, {1}, 'n_converge');
            results(subj, i, s, l) = n_converge;
            end
           
        end
        
    end
end



