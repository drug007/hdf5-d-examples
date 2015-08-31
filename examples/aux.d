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

    @disable this();

    static make()
    {
        alias TT = FieldTypeTuple!Data;

        auto tid = H5Tcreate (H5T_class_t.H5T_COMPOUND, DataSpecification!(Data).sizeof);
        DataAttribute[] attributes;

        foreach (member; __traits(allMembers, Data))
        {
            enum fullName = "Data." ~ member;
            mixin("alias T = typeof(" ~ fullName ~ ");");

            static if (staticIndexOf!(T, TT) != -1)
            {
                mixin("hid_t hdf5Type = " ~ typeToHdf5Type!T ~ ";");
                mixin("string varName = \"" ~ fullName ~ "\";");
                mixin("enum offset = Data." ~ member ~ ".offsetof;");
                auto attr = DataAttribute(hdf5Type, offset, varName);
                
                auto status = H5Tinsert(tid, attr.varName.ptr, attr.offset, attr.type);
                assert(status >= 0);

                attributes ~= attr;
            }
        }

        return DataSpecification!Data(tid, attributes);
    }

    this(const(hid_t) tid, DataAttribute[] attributes)
    {
        _tid = tid;
        _attributes = attributes;
    }

    ~this()
    {
        H5Tclose(_tid);
    }

    auto tid() const
    {
        return _tid;
    }

private:
    DataAttribute[] _attributes;
    immutable hid_t _tid;
    const(Data*) _data_ptr;
}

struct Dataset(Data)
{
    this(ref const(H5File) file, string name, ref const(DataSpace) space)
    {
        _data_spec = DataSpecification!Data.make();
        _dataset = H5Dcreate2(file._file, name.ptr, _data_spec.tid, space._space, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
        assert(_dataset >= 0);
    }

    this(ref const(H5File) file, string name)
    {
        _data_spec = DataSpecification!Data.make();
        _dataset = H5Dopen2(file._file, name.ptr, H5P_DEFAULT);
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

    /*
     * Read data from the dataset.
     */
    auto read(ref Data data)
    {
        auto status = H5Dread(_dataset, _data_spec.tid, H5S_ALL, H5S_ALL, H5P_DEFAULT, &data);
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

struct DataSpace
{
    this(int rank, hsize_t[] dim)
    {
        _space = H5Screate_simple(rank, dim.ptr, null);
        assert(_space >= 0);
    }

    ~this()
    {
        H5Sclose(_space);
    }

private:
    hid_t _space;
}

struct H5File
{
    @disable this();

    enum Access { 
        ReadOnly  = H5F_ACC_RDONLY, /*absence of rdwr => rd-only */
        ReadWrite = H5F_ACC_RDWR, /*open for read and write    */
        Trunc     = H5F_ACC_TRUNC, /*overwrite existing files   */
        Exclude   = H5F_ACC_EXCL, /*fail if file already exists*/
        Debug     = H5F_ACC_DEBUG, /*print debug info       */
        Create    = H5F_ACC_CREAT, /*create non-existing files  */
    };

    this(string filename, uint flags, hid_t fapl_id = H5P_DEFAULT, hid_t fcpl_id = H5P_DEFAULT)
    {
        // remove Access.Debug flag if any
        auto f = flags & (- cast(uint) Access.Debug - 1);
        if(((f == Access.Trunc) && (f != Access.Exclude)) ||
           ((f != Access.Trunc) && (f == Access.Exclude)))
        {
            _file = H5Fcreate(filename.ptr, flags, fcpl_id, fapl_id);
            assert(_file >= 0);
        }
        else
        if(((f == Access.ReadOnly) && (f != Access.ReadWrite)) ||
           ((f != Access.ReadOnly) && (f == Access.ReadWrite)))
        {
            _file = H5Fopen(filename.ptr, flags, fapl_id);
            assert(_file >= 0);
        }
        else
            assert(0, "Unknown flags combination.");
    }

    ~this()
    {
        /*
         * Release resources
         */
        H5Fclose(_file);
    }

private:
    hid_t _file;
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

    Foo foo = Foo(17, 9., 0.197);
    Foo foor;

    {
        auto space = DataSpace(RANK, dim);
        auto file  = H5File(filename, H5File.Access.Trunc);

        auto dataset = Dataset!Foo(file, datasetName, space);
        dataset.write(foo);
    }

    {
        auto file = H5File(filename, H5File.Access.ReadOnly);
        auto dataset = Dataset!Foo(file, datasetName);
        
        dataset.read(foor);
        writeln(foor);
        
        assert(foor == foo);
    }
}