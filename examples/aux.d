import std.traits;
import std.typetuple;

import hdf5.hdf5;

auto choice(T)(T typename)
{
    static if(is(T == int))
        mixin();
    else
        static assert(0);
}

private
{
    alias AllowedTypes = TypeTuple!(int, double);
    enum GLenum[] VectorHdf5Types =
    [
        H5T_NATIVE_INT,
        H5T_NATIVE_DOUBLE,
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
            enum typeToGLScalar = VectorHdf5Types[index];
    }
}

struct Helper(Datatype)
{

    
    void foo()
    {
        alias TT = FieldTypeTuple!Datatype;

        pragma(msg, TT.stringof);

        // Create all attribute description
        foreach (member; __traits(allMembers, Datatype))
        {
            enum fullName = "Datatype." ~ member;
            mixin("alias T = typeof(" ~ fullName ~ ");");

            static if (staticIndexOf!(T, TT) != -1)
            {
                pragma(msg, T.stringof);
                pragma(msg, (typeToHdf5Type!T).stringof);
        //        int location = program.attrib(member).location;
        //        mixin("enum size_t offset = Datatype." ~ member ~ ".offsetof;");

        //        enum UDAs = __traits(getAttributes, member);
        //        bool normalize = (staticIndexOf!(Normalized, UDAs) == -1);

        //        // detect suitable type
        //        int n;
        //        GLenum glType;
        //        toGLTypeAndSize!T(glType, n);
        //        _attributes ~= VertexAttribute(n, offset, glType, location, normalize ? GL_TRUE : GL_FALSE);

            }
        }
    }
}

void main()
{
    static struct Foo
    {
        int i;
        float f;
        double d;
        string str;
        ulong ul;
    }

    auto h = Helper!Foo();
}