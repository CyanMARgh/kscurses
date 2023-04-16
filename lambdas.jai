decl_lambda :: ($code_src : Code) -> Code #expand {
	node_src := compiler_get_nodes(code_src);
	proc_node, data_node, names, names_field, node_header, node_block := split_src(false, node_src);

	pair_names, pair_srcs := get_lambda_pairs(proc_node, data_node, names, names_field, node_header, node_block);

	return compiler_get_code(*Code_Compound_Declaration.{
		kind = .COMPOUND_DECLARATION,
		comma_separated_assignment = xx pair_names,
		declaration_properties = *Code_Declaration.{
			kind = .DECLARATION,
			expression = pair_srcs
		}
	});
}
assign_lambda :: ($code_src : Code, parent_scope := #caller_code) #expand {
	#insert,scope(parent_scope) #run _assign_lambda(code_src);	
}
struct_lambda :: ($code_src : Code, parent_scope := #caller_code) #expand {
	#insert,scope(parent_scope) #run _struct_lambda(code_src);
}
#scope_file
#import "Compiler";
#import "Basic";
#import "Program_Print";

_assign_lambda :: ($code_src : Code) -> Code {
	node_src := compiler_get_nodes(code_src);
	proc_node, data_node, names, names_field, node_header, node_block := split_src(false, node_src);

	pair_names, pair_srcs := get_lambda_pairs(proc_node, data_node, names, names_field, node_header, node_block);

	node_assign := Code_Binary_Operator.{
		kind = .BINARY_OPERATOR,
		operator_type = #char"=",
		left = pair_names,
		right = pair_srcs
	};
	return compiler_get_code(*node_assign);
}
_struct_lambda :: ($code_src : Code) -> Code {
	node_src := compiler_get_nodes(code_src);
	proc_node, data_node, names, names_field, node_header, node_block := split_src(true, node_src);

	pair_names, pair_srcs := get_lambda_pairs(proc_node, data_node, names, names_field, node_header, node_block);

	node_assign := Code_Binary_Operator.{
		kind = .BINARY_OPERATOR,
		operator_type = #char"=",
		left = pair_names,
		right = pair_srcs
	};
	return compiler_get_code(*node_assign);
}
//TODO add support for non-"proc/data" names
split_src :: (gen_pair : bool, node_src : *Code_Node) -> proc_node:*Code_Node, data_node:*Code_Node, names:[]string, names_field:[]string, node_header:*Code_Procedure_Header, node_block:*Code_Block #expand {
	offset := ifx gen_pair then 1 else 2;

	assert(node_src.kind == .BLOCK);
	node_src_block := cast(*Code_Block) node_src;
	node_src_statements := node_src_block.statements;
	captured_count := node_src_statements.count - 2 - offset;
	assert(captured_count >= 0);

	names := NewArray(captured_count, string);
	names_field := NewArray(captured_count, string);
	for i : offset..captured_count-1+offset {
		assert(node_src_statements[i].kind == .IDENT);
	}
	for i : 0..captured_count-1 {
		name := (cast(*Code_Ident)node_src_statements[i + offset]).name;
		names[i], names_field[i] = name, sprint("_%", name);
	}

	assert(node_src_statements[captured_count + offset].kind == .PROCEDURE_HEADER);
	node_header := cast(*Code_Procedure_Header) node_src_statements[captured_count + offset];
	assert(node_src_statements[captured_count + offset + 1].kind == .BLOCK);
	node_block := cast(*Code_Block) node_src_statements[captured_count + offset + 1];
	assert(node_block.block_type == .IMPERATIVE);

	proc_node, data_node : *Code_Node;
	if gen_pair {
		proc_node = *Code_Binary_Operator.{
			kind = .BINARY_OPERATOR,
			operator_type = #char".",
			left = node_src_statements[0],
			right = *Code_Ident.{
				kind = .IDENT,
				name = "proc"
			}
		};
		data_node = *Code_Binary_Operator.{
			kind = .BINARY_OPERATOR,
			operator_type = #char".",
			left = node_src_statements[0],
			right = *Code_Ident.{
				kind = .IDENT,
				name = "data"
			}
		};
	} else {
		proc_node, data_node = node_src_statements[0], node_src_statements[1];
	}

	return proc_node, data_node, names, names_field, node_header, node_block;
}
gen_struct_type_node :: (names : []string, names_field : []string) -> *Code_Node #expand {
	captured_count := names.count;

	nodes_ident := NewArray(captured_count, Code_Ident);
	nodes_ptr := NewArray(captured_count, Code_Unary_Operator);
	nodes_typeof := NewArray(captured_count, Code_Size_Or_Type_Info);
	nodes_type := NewArray(captured_count, Code_Type_Instantiation);
	nodes_declaration := NewArray(captured_count, Code_Declaration);
	nodes_declaration_ptr := NewArray(captured_count, *Code_Node);

	for i : 0..captured_count-1 {
		nodes_ident[i] = .{
			kind = .IDENT,
			name = names[i]
		};
		nodes_ptr[i] = .{
			kind = .UNARY_OPERATOR,
			operator_type = #char"*",
			subexpression = *(nodes_ident[i])			
		};
		nodes_typeof[i] = .{
			kind = .SIZE_OR_TYPE_INFO,
			query_kind = .TYPE_OF,
			type_of_expression = *(nodes_ptr[i])
		};
		nodes_type[i] = .{
			kind = .TYPE_INSTANTIATION,
			type_valued_expression = *(nodes_typeof[i])
		};
		nodes_declaration[i] = .{
			kind = .DECLARATION,
			name = names_field[i],
			type_inst = *(nodes_type[i])
		};
		nodes_declaration_ptr[i] = *(nodes_declaration[i]);
	}
	node_struct := Code_Struct.{
		kind = .STRUCT,
		block = *Code_Block.{
			kind = .BLOCK,
			block_type = .DATA_DECLARATIONS,
			statements = nodes_declaration_ptr
		}
	};
	return *node_struct;
}
//TODO better assertions
get_lambda_pairs :: (proc_node:*Code_Node, data_node:*Code_Node, names:[]string, names_field:[]string, node_header:*Code_Procedure_Header, node_block:*Code_Block) -> pair_names:*Code_Node, pair_srcs:*Code_Node #expand {
	node_0 := gen_struct_type_node(names, names_field);

	stat_count := node_block.statements.count;
	nodes_new_statements := NewArray(stat_count + 1, *Code_Node);
	for i : 0..stat_count-1 {
		nodes_new_statements[i + 1] = node_block.statements[i];
	}
	nodes_new_statements[0] = *Code_Using.{
		kind = .USING,
		expression = *Code_Cast.{
			kind = .CAST,
			target_type = *Code_Type_Instantiation.{
				kind = .TYPE_INSTANTIATION,
				type_valued_expression = *Code_Unary_Operator.{
					kind = .UNARY_OPERATOR,
					subexpression = node_0,
					operator_type = #char"*"
				}
			},
			expression = *Code_Ident.{
				kind = .IDENT,
				name = "__data"
			}
		}
	};

	arg_count := node_header.arguments.count;
	node_new_args := NewArray(arg_count + 1, *Code_Declaration);
	for i : 0..arg_count-1 {
		node_new_args[i] = node_header.arguments[i];
	}
	node_new_args[arg_count] = *Code_Declaration.{
		kind = .DECLARATION,
		name = "__data",
		type_inst = *Code_Type_Instantiation.{
			kind = .TYPE_INSTANTIATION,
			type_valued_expression = *Code_Unary_Operator.{
				kind = .UNARY_OPERATOR,
				operator_type = #char"*",
				subexpression = *Code_Ident.{
					kind = .IDENT,
					name = "void"
				}
			}
		}
	};

	nodes_13 := NewArray(names.count, Code_Ident);
	nodes_14 := NewArray(names.count, Code_Unary_Operator);
	nodes_14_ptr := NewArray(names.count, *Code_Node);

	for i : 0..names.count-1 {
		nodes_13[i] = Code_Ident.{
			kind = .IDENT,
			name = names[i]
		};
		nodes_14[i] = Code_Unary_Operator.{
			kind = .UNARY_OPERATOR,
			subexpression = *(nodes_13[i]),
			operator_type = #char"*"
		};
		nodes_14_ptr[i] = *(nodes_14[i]);
	}

	exprs : [2]*Code_Node;
	exprs[0] = *Code_Procedure_Header.{
		kind = .PROCEDURE_HEADER,
		arguments = node_new_args,
		returns = node_header.returns,
		body_or_null = *Code_Procedure_Body.{
			kind = .PROCEDURE_BODY,
			block = *Code_Block.{
				kind = .BLOCK,
				statements = nodes_new_statements
			}
		}
	};
	exprs[1] = *Code_Unary_Operator.{
		kind = .UNARY_OPERATOR,
		operator_type = #char"*",
		subexpression = *Code_Literal.{
			kind = .LITERAL,
			value_type = .STRUCT,
			struct_literal_info = *Code_Struct_Literal_Info.{
				type_expression = *Code_Type_Instantiation.{
					kind = .TYPE_INSTANTIATION,
					type_valued_expression = node_0
				},
				arguments = nodes_14_ptr
			}
		}
	};
	node_19 := Code_Comma_Separated_Arguments.{
		kind = .COMMA_SEPARATED_ARGUMENTS,
		expressions = exprs
	};
	exprs2 : [2]*Code_Node;
	exprs2[0] = proc_node;
	exprs2[1] = data_node;
	node_22 := Code_Comma_Separated_Arguments.{
		kind = .COMMA_SEPARATED_ARGUMENTS,
		expressions = exprs2
	};

	return *node_22, *node_19;
}
