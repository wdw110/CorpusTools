# Helper functions

function _to_array(r::Range1)
    a=Int[]
    for i in r
        push!(a, i)
    end
    return a
end

function _search_all(string::String, text::String, overlap=false)
    indic=Array[]
    i = 1
    while true
        rang =  (search(text, string, i))
        if length(rang)>0
            inds = [rang[1],rang[end]]
            push!(indic, inds)
            if overlap
                i = indic[end][2]
            else
                i = indic[end][end]
            end
        else
            return indic
        end
    end
end

###### Front end #######

# General functions

# IO operations

function load_files(name::String)
    f = open(name)
    text = readall(f)
    close(f)
    return text
end

function load_files(names::Array)
    texts = String[]
    if length(names)==1
        return load_files(names[1])
    end
    for name in names
        push!(texts, load_files(name))
    end
    return texts
end


load_files(files::Files) = return load_files(files.names)

function to_file(name::String, list_texts::Array, nl="\n")
    # Write grep_context output to a file

    f = open(name, "w")
    for text in list_texts
        write(f, string(text, nl))
    end
    close(f)
end

# Greps

# Count matches from a list of strings
grep_count(reg::Regex, text::String, overlap::Bool=false) = length(matchall(reg, text, overlap))

function grep_count(reg::Regex, list_texts::Array, overlap::Bool=false)
    # Count maches from a list of strings
    result=0
    for text in list_texts
        result += length(matchall(reg, text, overlap))
    end
    return result
end

function grep_count(reg::Regex, files::Files, overlap::Bool=false)
    # Count matches from a list of files
    result=0
    for name in files.names
        f = open(name)
        for text in eachline(f)
            result += length(matchall(reg, text, overlap))
        end
        close(f)
    end

    return result
end

# With sinple strings

function grep_count(str::String, text::String, overlap::Bool=false)
    return length(_search_all(str, text))
end

function grep_count(str::String, texts::Array, overlap::Bool=false)
    result = 0
    for text in texts
        result += grep_count(str, text, overlap)
    end
    return result
end

function grep_count(str::String, files::Files, overlap::Bool=false)
    # Count matches of string from a list of files
    result = 0
    for name in files.names
        f = open(name)
        for text in eachline(f)
            result +=length(_search_all(str, text))
        end
    end
    return result
end

# For concordance

# With simple strings

function grep_context(str::String, text::String, context=5, sep=" ")
    strings = String[]
    hits = _search_all(str, text)
    for indi in hits
        start = max(2,indi[1]-context)
        ende = min(length(text), indi[end]+context)
        push!(strings, string(text[start:indi[1]-1],
            sep,str,sep,text[indi[end]+1:ende]))
    end
    return strings
end

function grep_context(str::String, list_texts::Array, context=5, sep=" ")
    strings = String[]
    for text in list_texts
        strings = cat(1, strings, grep_context(str, text, context, sep))
    end
    return strings
end

function grep_context(str::String, files::Files, context=5, sep= " ")
    strings = String[]
    for name in files.names
        f = open(name)
        for text in eachline(f)
            strings = cat(1,strings, grep_context(str, text, context, sep))
        end
        close(f)
    end
    return strings
end

# With regular expresions

function grep_context(reg::Regex, text::String, context=5, sep= " ")
    # Grep from a single string of text
    strings = String[]
    for match in eachmatch(reg, text)
        id = match.offset
        idend = id+length(match.match)
        start = max(2, id-context)
        ende = min(length(text), idend+context)

        push!(strings, string(text[start:id-1], sep, match.match, sep, text[idend:ende]))
    end
    return strings
end

function grep_context(reg::Regex, list_texts::Array, context=5, sep=" ")
    # Grep read from a list of strings
    strings = String[]
    for text in list_texts
        strings = cat(1, strings, grep_context(reg, text, context, sep))
    end
    return strings
end

function grep_context(reg::Regex, files::Files, context=5, sep=" ")
    # Grep from a list of files
    strings = String[]
    for name in files.names
        f = open(name)
        for text in eachline(f)
            strings = cat(1,strings, grep_context(reg, text, context, sep))
        end
        close(f)
    end
    return strings
end

########
# Extract sentences containing...
########

function get_sentences(reg::Regex, files::Files, tagging="non"; sep = "<s")
    strings = String[]

    if tagging =="xml"
        for name in files.names
            text = readall(open(name))
            text = replace(text, r"<\?.*?\?>", "")
            text = replace(text, r"<header>.*?</header>", "")
            lines = split(text, r"(?=$(sep))")
            for string in lines
                if (ismatch(reg, string))
                    strings = cat(1,strings, string)
                end
            end
        end
    else
        for name in files.names
            f = open(name)
            for string in eachline(f)
                if (ismatch(reg, string))
                    strings = cat(1,strings, string)
                end
            end
            close(f)
        end
    end
    return strings
end

#taking an array of sentences
function get_sentences(reg::Regex, texts::Array{}; tagging="non")
    strings = String[]

    if tagging =="slash"

    elseif tagging =="xml"

    else
        for text in texts
            if (ismatch(reg, text))
                push!(strings, text)
            end
        end

    end
    return strings

end
