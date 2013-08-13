%% PoC Email Search Schema for Enron email using Enron mock-set.

{
    schema, 
    [
        {version, "0.1"},
        {n_val, 3},
        {default_field, "body_raw"},
        {analyzer_factory, {erlang, text_analyzers, standard_analyzer_factory}}
    ],
    [
        %% Don't parse the field, treat it as a single token.
        {field, [
            {name, "id"},
            {analyzer_factory, {erlang, text_analyzers, noop_analyzer_factory}}
        ]},

        %% Parse the customer ID as a single token and set it as inline for read performance.
        {field, [
            {name, "customer_id"},
            {inline, true},
            {analyzer_factory, {erlang, text_analyzers, noop_analyzer_factory}}
        ]},
        
        %% Don't parse the field, treat it as a single token.
        {field, [
            {name, "headers_Date"},
            {analyzer_factory, {erlang, text_analyzers, noop_analyzer_factory}}
        ]},

        %% Parse all other header_ (like To, From, etc.) as strings.
        {dynamic_field, [
            {name, "headers_*"},
            {analyzer_factory, {erlang, text_analyzers, standard_analyzer_factory}}
        ]},

        %% Parse all body text as full-text
        {field, [
            {name, "body_raw"},
            {analyzer_factory, {erlang, text_analyzers, whitespace_analyzer_factory}}
        ]},

        %% Everything else is ignored.
        {dynamic_field, [
            {name, "*"},
            {skip, true}
        ]}
    ]
}.