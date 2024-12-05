
"""
    generate_random_word_sequence(sequence_length, dictionary, silence_symbol; silent_intervals=1, weights=nothing)

Generate a random word sequence of a given length using a dictionary of words and their corresponding phonemes.

# Arguments
- `sequence_length::Int`: The desired length of the word sequence.
- `dictionary::Dict{Symbol, Vector{Symbol}}`: A dictionary mapping words to their corresponding phonemes.
- `silence_symbol::Symbol`: The symbol representing silence in the word sequence.

# Optional Arguments
- `silent_intervals::Int = 1`: The number of silent intervals between words.
- `weights::Union{Nothing, Vector{Float64}} = nothing`: The weights assigned to each word in the dictionary. If `nothing`, all words have equal weight.

# Returns
- `words::Vector{Symbol}`: The generated word sequence.
- `phonemes::Vector{Symbol}`: The corresponding phonemes for each word in the sequence.
"""
function word_phonemes_sequence(
    lexicon;
    weights = nothing,
    seed = nothing,
    silent_intervals = 1,
    repetition::Int,
    kwargs...
)


    @unpack dict, symbols, silence_symbol, ph_duration = lexicon
    if seed !== nothing
        Random.seed!(seed)
    end 


    dict_words = collect(keys(dict))
    weights = isnothing(weights) ? fill(1, length(dict_words)) : [weights[word] for word in dict_words]
    weights = StatsBase.Weights(weights)
    word_frequency = Dict{Symbol,Int}()
    words, phonemes = [], []

    remaining_words = copy(dict_words)
    make_equal = true

    seq_length = round(Int, length(dict_words)*repetition* mean([length(dict[word]) for word in dict_words]))
    while length(words) < seq_length
        current_word = choose_word(make_equal, remaining_words, dict_words, weights, word_frequency)
        word_phonemes = dict[current_word]

        if haskey(word_frequency, current_word)
            word_frequency[current_word] += 1
        else
            word_frequency[current_word] = 1
        end

        if should_fill_with_silence(word_phonemes, silent_intervals, seq_length, length(words))
            fill_with_silence!(words, phonemes, silence_symbol, seq_length - length(words))
        else
            append_word_and_phonemes!(words, phonemes, current_word, word_phonemes, silence_symbol, silent_intervals)
        end
    end

    return words, phonemes, seq_length
end

function vot_sequence(
    sequence_length::Int,
    dictionary::Dict{Symbol, Vector{Symbol}},
    silence_symbol::Symbol;
    weights = nothing,
    silent_intervals = 1,
    vot_duration = nothing
)

    dict_words = collect(keys(dictionary))

    weights = isnothing(weights) ? fill(1, length(dict_words)) : [weights[word] for word in dict_words]
    weights = StatsBase.Weights(weights)

    word_frequency = Dict{Symbol,Int}()
    words, phonemes = [], []

    remaining_words = copy(dict_words)
    make_equal = true

    sequence_length = round(Int, dict_words*repetition* mean([length(dictionary[word]) for word in dict_words])), 
    while length(words) < sequence_length
        current_word = choose_word(make_equal, remaining_words, dict_words, weights, word_frequency)
        word_phonemes = dictionary[current_word]

        if haskey(word_frequency, current_word)
            word_frequency[current_word] += 1
        else
            word_frequency[current_word] = 1
        end

        if should_fill_with_silence(word_phonemes, silent_intervals, sequence_length, length(words))
            fill_with_silence!(words, phonemes, silence_symbol, sequence_length - length(words))
        else
            word_count[word] = 1
        end
            if length(phs) + silent_intervals > seq_length - _seq_length
                while _seq_length < seq_length
                    _seq_length += 1
                    push!(words, silence_symbol)
                    push!(phonemes, silence_symbol)
                end
                continue
            end
            for (i, ph) in enumerate(phs)
                push!(phonemes, ph)
                push!(words, word)
                _seq_length += 1

                # Add the phoneme spacing symbol after each phoneme, except the last
                if i < length(phs) && !isnothing(vot_duration)
                    ph_space_symbol = Symbol("_" * string(word))  # Get the matching symbol for ph
                    push!(phonemes, ph_space_symbol)  # Add space symbol
                    push!(words, word)  # Null for spacing
                    _seq_length += 1
                end
            end
            for _ = 1:silent_intervals
                push!(words, silence_symbol)
                push!(phonemes, silence_symbol)
                _seq_length += 1
        end
    end

    return words, phonemes
end


# What is this function doing?
# function generate_sequence_variable(lexicon, config, seed=nothing)

#     if seed !== nothing
#         Random.seed!(seed)
#     end 

#     @unpack seq_length, vot_duration = config
#     @unpack dict, id2string, string2id, symbols, silence_symbol, ph_duration = lexicon
#     silent_intervals = 1
#     words, phonemes = get_words(
#         seq_length,
#         dict,
#         silence_symbol,
#         silent_intervals = silent_intervals;
#         vot_duration = vot_duration
#     )

#     ## create the populations
#     ## sequence from the initial word sequence
#     silence = string2id[silence_symbol]
#     if haskey(config,:init_silence)
#         sequence = fill(silence, 3, seq_length+1)
#         sequence[1, 1] = silence
#         sequence[2, 1] = silence
#         sequence[3, 1] = config.init_silence
#         for (n, (w, p)) in enumerate(zip(words, phonemes))
#             sequence[1, 1+n] = string2id[w]
#             sequence[2, 1+n] = string2id[p]
#             if p in keys(vot_duration)
#                 min, max = vot_duration[p]
#                 space_duration = rand(min:max)
#                 sequence[3, 1+n] = space_duration
#             else
#                 sequence[3, 1+n] = ph_duration[p]
#             end
#         end
#     else
#         sequence = fill(silence, 3, seq_length)
#         for (n, (w, p)) in enumerate(zip(words, phonemes))
#             sequence[1, n] = string2id[w]
#             sequence[2, n] = string2id[p]
#             if p in keys(vot_duration)
#                 min, max = vot_duration[p]
#                 space_duration = rand(min:max)
#                 sequence[3, n] = space_duration
#             else
#                 sequence[3, n] = ph_duration[p]
#             end
#         end
#     end

#     line_id = (phonemes=2, words=1, duration=3)
#     sequence = (;lexicon...,
#                 sequence=sequence,
#                 line_id = line_id)

# end


"""
    choose_word(make_equal, remaining_words, dict_words, weights, word_frequency)

Choose a word from the given list of words based on the specified criteria.

Arguments:
- `make_equal`: A boolean indicating whether the words should be chosen with equal probability.
- `remaining_words`: A list of words that have not been chosen yet.
- `dict_words`: A list of all available words.
- `weights`: A list of weights corresponding to each word in `dict_words`.
- `word_frequency`: A dictionary mapping words to their frequencies.

Returns:
- A word chosen based on the specified criteria.
"""
function choose_word(make_equal, remaining_words, dict_words, weights, word_frequency)
    if make_equal
        return !isempty(remaining_words) ? pop!(remaining_words) :
               StatsBase.sample(dict_words, StatsBase.Weights([exp(-word_frequency[word]) for word in dict_words]))
    else
        return StatsBase.sample(dict_words, weights)
    end
end

"""
    should_fill_with_silence(word_phonemes, silent_intervals, sequence_length, current_length)

Check if the remaining sequence should be filled with silence.

Arguments:
- `word_phonemes`: The number of phonemes in the current word.
- `silent_intervals`: The number of silent intervals.
- `sequence_length`: The total length of the sequence.
- `current_length`: The current length of the sequence.

Returns:
- A boolean indicating whether the remaining sequence should be filled with silence.
"""
function should_fill_with_silence(word_phonemes, silent_intervals, sequence_length, current_length)
    return length(word_phonemes) + silent_intervals > sequence_length - current_length
end

"""
    fill_with_silence!(words, phonemes, silence_symbol, fill_count)

Fill the given lists with silence symbols.

Arguments:
- `words`: A list of words.
- `phonemes`: A list of phonemes.
- `silence_symbol`: The symbol representing silence.
- `fill_count`: The number of times to fill with silence.
"""
function fill_with_silence!(words, phonemes, silence_symbol, fill_count)
    for _ in 1:fill_count
        push!(words, silence_symbol)
        push!(phonemes, silence_symbol)
    end
end

"""
    append_word_and_phonemes!(words, phonemes, word, phonemes_list, silence_symbol, silent_intervals)

Append a word and its corresponding phonemes to the given lists.

Arguments:
- `words`: A list of words.
- `phonemes`: A list of phonemes.
- `word`: The word to append.
- `phonemes_list`: A list of phonemes corresponding to the word.
- `silence_symbol`: The symbol representing silence.
- `silent_intervals`: The number of silent intervals to append after the word.
"""
function append_word_and_phonemes!(words, phonemes, word, phonemes_list, silence_symbol, silent_intervals)
    for ph in phonemes_list
        push!(phonemes, ph)
        push!(words, word)
    end

    for _ = 1:silent_intervals
        push!(words, silence_symbol)
        push!(phonemes, silence_symbol)
    end
end

# function silence_sequence!(seq::Encoding)
#     @assert(length(seq.populations) == seq.silence)
#     @assert(seq.populations[seq.silence] == [])
#     fill!(seq.sequence, seq.silence)
# end

# function silence_sequence(seq::Encoding)
#     new_seq = deepcopy(seq)
#     silence_sequence!(new_seq)
#     return new_seq
# end
"""
    step_input_sequence(; network, targets=[:d], lexicon, config_sequence, seed=1234)

Generate a sequence input for a spiking neural network.

# Arguments
- `network`: The spiking neural network object.
- `targets`: An array of target neurons to stimulate. Default is `[:d]`.
- `lexicon`: The lexicon object containing the sequence symbols.
- `config_sequence`: The configuration for generating the sequence.

# Returns
- `stim`: A named tuple of stimuli for each symbol in the sequence.
- `seq`: The generated sequence.

"""
function step_input_sequence(;network, 
    targets, 
    words, 
    lexicon, 
    p_post, 
    peak_rate, 
    start_rate, 
    proj_strength,
    decay_rate,
    kwargs...)

    @unpack E = network.pop
    seq = generate_sequence(lexicon, word_phonemes_sequence; kwargs...)


    stim = Dict{Symbol,Any}()
    parameters = Dict(:decay=>decay_rate, :peak=>peak_rate, :start=>start_rate)

    for s in seq.symbols.words
        variables = merge(parameters, Dict(:intervals=>sign_intervals(s, seq)))
        param = PSParam(rate=attack_decay, 
                    variables=variables)
        for t in targets
            push!(stim, Symbol(string(s,"_",t))  => SNN.PoissonStimulus(E, :he, t, μ=proj_strength, param=param, name="w_$s", p_post=p_post))
            if !words
                getfield(stim, Symbol(string(s,"_",t)) ).param.active[1] = false
            end
        end
    end
    for s in seq.symbols.phonemes
        variables = merge(parameters, Dict(:intervals=>sign_intervals(s, seq)))
        param = PSParam(rate=attack_decay, 
                    variables=variables)
        for t in targets
            push!(stim,Symbol(string(s,"_",t))  => SNN.PoissonStimulus(E, :he, t, μ=proj_strength, param=param, name="$s", p_post=p_post) 
            )
        end
    end
    stim = dict2ntuple(stim)
    stim, seq
end

function randomize_sequence!(;seq, model, targets::Vector{Symbol}, words=true, kwargs...)
    new_seq = generate_sequence(seq, word_phonemes_sequence; kwargs...)
    @unpack stim = model
    for target in targets
        for s in seq.symbols.words
            getfield(stim, Symbol(string(s,"_",target)) ).param.variables[:intervals] = sign_intervals(s, new_seq)
            if !words 
                getfield(stim, Symbol(string(s,"_",target)) ).param.active[1] = false
            end
        end
        for s in seq.symbols.phonemes
            getfield(stim, Symbol(string(s,"_",target)) ).param.variables[:intervals] = sign_intervals(s, new_seq)
        end
    end
    return new_seq
end


function dummy_input(x, param::PSParam)
    return 0kHz
end


"""
    attack_decay(x, param::PSParam)

    Generate an attack-decay function for the PoissonStimulus. 
    It requires these parameters in the PoissonStimulusParameter object:
    - `intervals`: The intervals for the attack-decay function.
    - `decay`: The decay rate for the function.
    - `peak`: The peak rate for the function.
    - `start`: The start rate for the function.
    
    The attack decay function is defined as:

    f(x) = peak + (start-peak) *(exp(-(x-my_interval)/decay))

"""
function attack_decay(x, param::PSParam) 
    intervals::Vector{Vector{Float32}} = param.variables[:intervals]
    decay::Float32 = param.variables[:decay]
    peak::Float32 = param.variables[:peak]
    start::Float32 = param.variables[:start]
    if time_in_interval(x, intervals)
        my_interval::Float32 = start_interval(x, intervals)
        return peak + (start-peak)*(exp(-(x-my_interval)/decay)) 
        # return 0kHz
    else
        return 0kHz
    end
end
# scatter(new_seq.sequence[1,:], seq.sequence[1,:], label="New sequence", c=:black, alpha=0.01, ms=10)


export step_input_sequence, randomize_sequence!, dummy_input, attack_decay