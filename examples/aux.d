import std.traits;
import std.typetuple;

import hdf5.hdf5;

auto choice(T)(T typename)
{
    static if(is(T == int))
        mixin("");
    else
        static assert(0);
}

private
{
    alias AllowedTypes = TypeTuple!(float, int, double);
    enum string[]/*GLenum[]*/ VectorHdf5Types =
    [
        "H5T_NATIVE_FLOAT",
        "H5T_NATIVE_INT",
        "H5T_NATIVE_DOUBLE",
    ];

    template typeToHdf5Type(T)
    {
        alias U = Unqual!T;
        enum index = staticIndexOf!(U, AllowedTypes);
        static if (index == -1)
        {
            static assert(false, "Could not use " ~ T.stringof ~ ", there is no corresponding hdf5 data type");
        }
        else
        {
            enum typeToHdf5Type = VectorHdf5Types[index];
        }
    }
}

struct DataAttribute
{
    hid_t type;
    string typeName;
}

struct DataSpecification(Data)
{    
    this(Data data)
    {
        alias TT = FieldTypeTuple!Data;

        foreach (member; __traits(allMembers, Data))
        {
            enum fullName = "Data." ~ member;
            mixin("alias T = typeof(" ~ fullName ~ ");");

            static if (staticIndexOf!(T, TT) != -1)
            {
                mixin("hid_t hdf5Type = " ~ typeToHdf5Type!T ~ ";");
                mixin("string hdf5TypeName = \"" ~ typeToHdf5Type!T ~ "\";");
                _attributes ~= DataAttribute(hdf5Type, hdf5TypeName);
            }
        }
    }
private:
    DataAttribute[] _attributes;
}

void main()
{
    import std.stdio;

    H5open();
    
    static struct Foo
    {
        int i;
        float f;
        double d;
        //string str;
        //ulong ul;
    }

    auto foo = Foo();
    writeln(DataSpecification!Foo(foo));
}