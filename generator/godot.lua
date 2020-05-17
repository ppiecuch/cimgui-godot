local structs = dofile( "output/structs_and_enums.lua" )
local defs = dofile( "output/definitions.lua" )

function camelcase_to_underscore(s)
    return s:gsub("%u", "_%1"):gsub(".", string.lower):gsub("^_", "")
end

file_cpp = io.open ("gimgui_binding.cpp", "w")
file_h = io.open ("gimgui_binding.h", "w")

file_h:write("#include \"core/reference.h\"\n\n")

print( "*** Structures and enums .." )

for key, value in pairs(structs['structs']) do
    file_h:write("class "..key.." : public Reference {\n")
    file_h:write("\tGDCLASS("..key..", Reference);\n")
    file_h:write("private:\n")
    for i,struct in pairs(value) do
        file_h:write("\t"..struct.type.." "..struct.name..",\n")
    end
    file_h:write("public:\n")
    file_h:write("\tstatic void _bind_methods();\n\n")
    for i,struct in pairs(value) do
        file_h:write("\t"..struct.type.." set_"..camelcase_to_underscore(struct.name).."("..struct.type.." p_val);\n")
        file_h:write("\tvoid get_"..camelcase_to_underscore(struct.name).."();\n")
    end
    file_h:write("}; // " .. key, "\n\n")
end

file_h:write("\nclass GdImgui : public Reference {\n")
file_h:write("\tGDCLASS(GdImgui, Reference);\n\n")

file_h:write("public:\n")
local varriant_enum_h = ""
local varriant_enum_cpp = ""
for key, value in pairs(structs['enums']) do
    file_h:write("\tenum " .. key, "{\n")
    varriant_enum_h = varriant_enum_h.."VARIANT_ENUM_CAST(GdImgui::"..key..");\n"
    varriant_enum_cpp = varriant_enum_cpp.."// bind constants from "..key..":\n"
    for i,enum in pairs(value) do
        file_h:write("\t\t"..enum.name..",\n")
        varriant_enum_cpp = varriant_enum_cpp.."BIND_ENUM_CONSTANT("..enum.name..");\n"
    end
    file_h:write("\t};\n")
end

print( "*** Definitions .." )

file_h:write("public:\n")
file_h:write("\tstatic void _bind_methods();\n\n")

file_h:write("\tGdImgui();\n")
file_h:write("\t~GdImgui();\n\n")

file_h:write("\t// Imgui API\n")
for key, value in pairs(defs) do
    for i,func in pairs(value) do
        if func.namespace == "ImGui" then
            if func.ret then
                if func.ret == "const char*" then
                    file_h:write("\tString")
                else
                    file_h:write("\t"..func.ret)
                end
            else
                file_h:write("\tvoid")
            end
            file_h:write(" "..key.."();\n")
        end
    end
end
file_h:write("\t// End.\n")
file_h:write("} // GdImgui\n\n")

file_h:write(varriant_enum_h)

file_cpp:write(varriant_enum_cpp)
