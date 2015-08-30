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
    size_t offset;
    string varName;
}

struct DataSpecification(Data) if(is(Data == struct))
{    
    alias DataType = Data;

    this(ref Data data)
    {
        alias TT = FieldTypeTuple!Data;

        foreach (member; __traits(allMembers, Data))
        {
            enum fullName = "Data." ~ member;
            mixin("alias T = typeof(" ~ fullName ~ ");");

            static if (staticIndexOf!(T, TT) != -1)
            {
                mixin("hid_t hdf5Type = " ~ typeToHdf5Type!T ~ ";");
                mixin("string varName = \"" ~ fullName ~ "\";");
                mixin("enum offset = Data." ~ member ~ ".offsetof;");
                _attributes ~= DataAttribute(hdf5Type, offset, varName);
            }
        }

        _tid = H5Tcreate (H5T_class_t.H5T_COMPOUND, DataSpecification!(Data).sizeof);
        _data_ptr = &data;

        foreach(da; _attributes)
        {
            auto status = H5Tinsert(_tid, da.varName.ptr, da.offset, da.type);
            assert(status >= 0);
        }
    }

    ~this()
    {
        H5Tclose(_tid);
    }

    auto tid() const
    {
        return _tid;
    }

    auto dataPtr() const
    {
        return _data_ptr;
    }

private:
    DataAttribute[] _attributes;
    immutable hid_t _tid;
    const(Data*) _data_ptr;
}

struct Dataset(Data)
{
    this(hid_t file, string name, hid_t space, ref Data data)
    {
        _data_spec = DataSpecification!Data(data);
        _dataset = H5Dcreate2(file, name.ptr, _data_spec.tid, space, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
        assert(_dataset >= 0);
    }

    /*
     * Wtite data to the dataset; 
     */ 
    auto write(ref Data data)
    {
        auto status = H5Dwrite(_dataset, _data_spec.tid, H5S_ALL, H5S_ALL, H5P_DEFAULT, &data);
        assert(status >= 0);
    }

    ~this()
    {
        H5Dclose(_dataset);
    }

private:
    hid_t _dataset;
    DataSpecification!Data _data_spec;
}

void main()
{
    import std.stdio;

    enum RANK   = 1;
    enum LENGTH = 1;

    hsize_t[1] dim = [ LENGTH ];   /* Dataspace dimensions */

    string filename    = "autocompound.h5";
    string datasetName = "dataset";

    H5open();
    
    static struct Foo
    {
        int i;
        float f;
        double d;
        //string str;
        //ulong ul;
    }

    /*
     * Create the data space.
     */
    auto space = H5Screate_simple(RANK, dim.ptr, null);
    assert(space >= 0);

    /*
     * Create the file.
     */
    auto file = H5Fcreate(filename.ptr, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);
    assert(file >= 0);

    auto foo = Foo();
    auto foo_hdf5 = DataSpecification!Foo(foo);

    /* 
     * Create the dataset.
     */
    auto dataset = H5Dcreate2(file, datasetName.ptr, foo_hdf5.tid, space, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    assert(dataset >= 0);

    /*
     * Wtite data to the dataset; 
     */ 
    auto status = H5Dwrite(dataset, foo_hdf5.tid, H5S_ALL, H5S_ALL, H5P_DEFAULT, &foo);
    assert(status >= 0);

    /*
     * Release resources
     */
    H5Sclose(space);
    H5Dclose(dataset);
    H5Fclose(file);
}